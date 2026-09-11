mod api;
mod config;
mod infra;
mod models;
mod oauth;
mod schema;
mod sessions;
mod tokens;

use std::{collections::HashMap, env, str::FromStr};

use axum::{
    Extension, Router,
    body::Body,
    extract::{self, FromRequestParts},
    http::{Response, StatusCode, header::LOCATION},
    routing::{any, get},
};
use diesel::{Connection as _, PgConnection};
use diesel_migrations::{EmbeddedMigrations, MigrationHarness as _, embed_migrations};
use dotenvy::dotenv;
use http::{
    HeaderMap, HeaderName, HeaderValue, Uri,
    header::{CACHE_CONTROL, CONNECTION, COOKIE, HOST, TRANSFER_ENCODING, USER_AGENT},
};
use openidconnect::{
    AuthorizationCode, ClientId, ClientSecret, EmptyExtraTokenFields, EndpointMaybeSet,
    EndpointNotSet, EndpointSet, IdToken, IdTokenFields, IssuerUrl, PkceCodeVerifier, RedirectUrl,
    StandardErrorResponse, StandardTokenResponse,
    core::{
        CoreAuthDisplay, CoreAuthPrompt, CoreErrorResponseType, CoreGenderClaim, CoreJsonWebKey,
        CoreJweContentEncryptionAlgorithm, CoreJwsSigningAlgorithm, CoreProviderMetadata,
        CoreRevocableToken, CoreRevocationErrorResponse, CoreTokenIntrospectionResponse,
        CoreTokenType,
    },
    reqwest,
};
use serde::{Deserialize, Serialize};
use tower::ServiceExt as _;
use tower_http::{
    cors::CorsLayer,
    trace::{DefaultMakeSpan, TraceLayer},
};
use tracing::{Level, info};

use crate::{
    config::{AppDefinition, Config, OAuthConfiguration},
    infra::DatabaseConnector,
    oauth::{OAuthSessionData, User},
    sessions::{SessionHandle, SessionLayer},
};

type OAuth2IdToken = IdToken<
    oauth::AdditionalClaims,
    CoreGenderClaim,
    CoreJweContentEncryptionAlgorithm,
    CoreJwsSigningAlgorithm,
>;
type OAuth2IdTokenFields = IdTokenFields<
    oauth::AdditionalClaims,
    EmptyExtraTokenFields,
    CoreGenderClaim,
    CoreJweContentEncryptionAlgorithm,
    CoreJwsSigningAlgorithm,
>;
type OAuth2TokenResponse = StandardTokenResponse<OAuth2IdTokenFields, CoreTokenType>;

type OAuth2Client = openidconnect::Client<
    oauth::AdditionalClaims,
    CoreAuthDisplay,
    CoreGenderClaim,
    CoreJweContentEncryptionAlgorithm,
    CoreJsonWebKey,
    CoreAuthPrompt,
    StandardErrorResponse<CoreErrorResponseType>,
    OAuth2TokenResponse,
    CoreTokenIntrospectionResponse,
    CoreRevocableToken,
    CoreRevocationErrorResponse,
    EndpointSet,
    EndpointNotSet,
    EndpointNotSet,
    EndpointNotSet,
    EndpointMaybeSet,
    EndpointMaybeSet,
>;

#[derive(Debug, Clone)]
enum AuthenticationMethodState {
    OAuth {
        client: Box<OAuth2Client>,
        required_entitlement: Option<String>,
    },
    Token,
}

#[derive(Debug, Clone)]
struct ProviderState {
    definition: Option<AppDefinition>,
    authentication_methods: Vec<AuthenticationMethodState>,
    base_url: String,
}

#[derive(Clone)]
struct OuterState {
    inner_router: Router,
    state: AppState,
}

#[derive(Clone)]
struct AppState {
    config: Config,
    database: DatabaseConnector,
    providers: HashMap<String, ProviderState>,
    oidc_http_client: reqwest::Client,
    backend_http_client: ::reqwest::Client,
}

struct Hostname(String);

impl<S: Send + Sync> FromRequestParts<S> for Hostname {
    type Rejection = (StatusCode, &'static str);

    async fn from_request_parts(
        parts: &mut http::request::Parts,
        _state: &S,
    ) -> Result<Self, Self::Rejection> {
        let host_header = parts.headers.get("Host").unwrap().to_str().unwrap();
        let host = &host_header[..host_header.rfind(':').unwrap_or(host_header.len())];

        Ok(Self(host.to_string()))
    }
}

#[axum::debug_handler]
async fn root_route(
    extract::State(state): extract::State<OuterState>,
    Hostname(host): Hostname,
    request: extract::Request,
) -> Response<Body> {
    if host == state.state.config.hostname {
        state
            .inner_router
            .into_service()
            .oneshot(request)
            .await
            .unwrap()
    } else {
        let (mut parts, body) = request.into_parts();

        let user = match User::from_request_parts(&mut parts, &()).await {
            Ok(u) => u,
            Err(e) => return e,
        };

        let state = &state.state;

        // TODO throw a 404 if not found
        let provider = state.providers.get(&host).unwrap();

        let target_uri = ::reqwest::Url::from_str(&format!(
            "{}{}",
            provider.definition.as_ref().unwrap().backend,
            parts
                .uri
                .path_and_query()
                .map(|x| x.to_string())
                .unwrap_or_default()
        ))
        .unwrap();

        let mut proxy_headers = HeaderMap::new();
        if let Some(ua) = parts.headers.get(USER_AGENT) {
            proxy_headers.insert(USER_AGENT, ua.clone());
        }
        proxy_headers.insert(HOST, HeaderValue::from_str(target_uri.authority()).unwrap());
        proxy_headers.insert("X-User-Id", HeaderValue::from_str(user.id()).unwrap());
        proxy_headers.insert(
            "X-Auth-Method",
            HeaderValue::from_str(&user.auth_method().to_string()).unwrap(),
        );

        if let Some(user_name) = user.name() {
            proxy_headers.insert("X-User-Name", HeaderValue::from_str(user_name).unwrap());
        }

        if let Some(expiration) = user.expiration() {
            proxy_headers.insert(
                "X-User-Expiration",
                HeaderValue::from_str(&expiration.to_rfc3339()).unwrap(),
            );
        }

        if let Some(cookie) = parts.headers.get(COOKIE) {
            proxy_headers.insert(COOKIE, cookie.clone());
        }

        let mut proxy_request = ::reqwest::Request::new(parts.method.clone(), target_uri.clone());
        *proxy_request.headers_mut() = proxy_headers.clone();
        *proxy_request.body_mut() = Some(::reqwest::Body::wrap_stream(body.into_data_stream()));

        info!(
            ?target_uri,
            backend = provider.definition.as_ref().unwrap().backend,
            request = ?proxy_request,
            "proxying request"
        );

        let reqwest_response = state
            .backend_http_client
            .execute(proxy_request)
            .await
            .unwrap();
        let mut headers = reqwest_response.headers().clone();
        headers.remove(CONNECTION);
        headers.remove(TRANSFER_ENCODING);
        headers.remove(HeaderName::from_static("keep-alive"));
        headers.insert(
            CACHE_CONTROL,
            HeaderValue::from_static("no-cache, no-store"),
        );
        let status = reqwest_response.status();

        let response_bytes = reqwest_response.bytes().await.unwrap();
        let body = Body::from(response_bytes);

        let mut response = Response::new(body);
        *response.headers_mut() = headers;
        *response.status_mut() = status;

        response
    }
}

#[derive(Debug, Serialize, Deserialize)]
struct AuthroizeQuery {
    code: String,
    state: String,
}

#[axum::debug_handler]
async fn get_authorize(
    extract::Extension(state): extract::Extension<AppState>,
    extract::Query(query): extract::Query<AuthroizeQuery>,
    session: extract::Extension<SessionHandle>,
) -> (StatusCode, HeaderMap, String) {
    let mut oauth_session_state: OAuthSessionData = session.data().await.oauth.unwrap();

    if &query.state != oauth_session_state.csrf_token.secret() {
        return (
            StatusCode::BAD_REQUEST,
            HeaderMap::new(),
            "invalid csrf_token".into(),
        );
    }

    let return_url: Uri = oauth_session_state.return_url.parse().unwrap();

    // TODO 404 if it's missing
    let provider = state
        .providers
        .get(return_url.authority().unwrap().host())
        .unwrap();

    let client = provider
        .authentication_methods
        .iter()
        .filter_map(|x| {
            if let AuthenticationMethodState::OAuth {
                client,
                required_entitlement: _,
            } = x
            {
                Some(client)
            } else {
                None
            }
        })
        .next()
        .unwrap();

    let pkce_verifier = PkceCodeVerifier::new(oauth_session_state.pkce_verifier.clone());
    let token_response = client
        .exchange_code(AuthorizationCode::new(query.code))
        .unwrap()
        .set_pkce_verifier(pkce_verifier)
        .request_async(&state.oidc_http_client)
        .await
        .unwrap();

    oauth_session_state.id_token = Some(token_response.extra_fields().id_token().unwrap().clone());
    session
        .update(|s| s.oauth = Some(oauth_session_state))
        .await;

    let mut headers = HeaderMap::new();
    headers.insert(
        LOCATION,
        HeaderValue::from_str(&return_url.to_string()).unwrap(),
    );

    (StatusCode::FOUND, headers, String::new())
}

pub const MIGRATIONS: EmbeddedMigrations = embed_migrations!("migrations/");

async fn make_oauth_client(
    configuration: &OAuthConfiguration,
    http_client: &reqwest::Client,
    base_url: String,
) -> OAuth2Client {
    let provider_metadata = CoreProviderMetadata::discover_async(
        IssuerUrl::new(configuration.oidc_issuer_url.clone()).unwrap(),
        http_client,
    )
    .await
    .unwrap();

    let redirect_uri = http::Uri::from_str(&format!("{}/authorize", base_url)).unwrap();

    OAuth2Client::from_provider_metadata(
        provider_metadata.clone(),
        ClientId::new(configuration.client_id.clone()),
        Some(ClientSecret::new(configuration.client_secret.clone())),
    )
    .set_redirect_uri(RedirectUrl::new(redirect_uri.to_string()).unwrap())
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt().init();
    let _ = dotenv();

    let config = config::load().unwrap();
    let database_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    PgConnection::establish(&database_url)
        .expect("failed to connect to the database")
        .run_pending_migrations(MIGRATIONS)
        .unwrap();

    let auth_http_client = reqwest::ClientBuilder::new()
        .redirect(reqwest::redirect::Policy::none())
        .build()
        .unwrap();

    let backend_http_client = ::reqwest::ClientBuilder::new()
        .redirect(::reqwest::redirect::Policy::none())
        .build()
        .unwrap();

    let mut providers = HashMap::new();
    for (host, app_definition) in &config.apps {
        let mut authentication_methods = vec![];
        for authentication_method in &app_definition.auth_methods {
            let authentication_method = match authentication_method {
                config::AuthMethod::OAuth(oauth_configuration) => {
                    AuthenticationMethodState::OAuth {
                        client: Box::new(
                            make_oauth_client(
                                &config.api.oauth,
                                &auth_http_client,
                                config.base_url.clone(),
                            )
                            .await,
                        ),
                        required_entitlement: oauth_configuration.required_entitlement.clone(),
                    }
                }
                config::AuthMethod::Token => AuthenticationMethodState::Token,
            };
            authentication_methods.push(authentication_method);
        }

        providers.insert(
            host.to_string(),
            ProviderState {
                authentication_methods,
                base_url: app_definition.base_url.clone(),
                definition: Some(app_definition.clone()),
            },
        );
    }

    providers.insert(
        config.hostname.clone(),
        ProviderState {
            authentication_methods: vec![AuthenticationMethodState::OAuth {
                client: Box::new(
                    make_oauth_client(
                        &config.api.oauth,
                        &auth_http_client,
                        config.base_url.clone(),
                    )
                    .await,
                ),
                required_entitlement: config.api.oauth.required_entitlement.clone(),
            }],
            base_url: config.base_url.clone(),
            definition: None,
        },
    );

    let cookie_domain = config.cookie_domain.clone();

    let state = AppState {
        config,
        oidc_http_client: auth_http_client,
        providers,
        backend_http_client,
        database: DatabaseConnector::new(database_url),
    };

    let inner_router = Router::new()
        .route("/", get(async || "hi"))
        .route("/authorize", get(get_authorize))
        .nest("/api/v1", api::router(state.clone()))
        .layer(Extension(state.clone()))
        .layer(SessionLayer::new(
            state.database.clone(),
            cookie_domain.clone(),
        ));

    let router = Router::new()
        .route("/", any(root_route))
        .route("/{*all}", any(root_route))
        .with_state(OuterState {
            // TODO remove the AppState from here and only pass the inner_router
            state: state.clone(),
            inner_router,
        })
        .layer(Extension(state.clone()))
        .layer(TraceLayer::new_for_http().make_span_with(DefaultMakeSpan::new().level(Level::INFO)))
        .layer(SessionLayer::new(state.database.clone(), cookie_domain))
        // TODO only allow *.ramona.fun
        .layer(CorsLayer::very_permissive());

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();

    axum::serve(listener, router).await.unwrap();
}
