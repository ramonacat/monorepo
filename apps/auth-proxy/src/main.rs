mod api;
mod auth;
mod config;
mod infra;
mod models;
mod mtls;
mod oauth;
mod schema;
mod sessions;

use std::{collections::HashMap, env, net::SocketAddr, str::FromStr, sync::Arc};

use axum::{
    Extension, Router,
    body::Body,
    extract::{self, FromRequestParts},
    http::{Response, StatusCode, header::LOCATION},
    routing::{any, get},
};
use axum_server::tls_rustls::RustlsConfig;
use diesel::{Connection as _, PgConnection};
use diesel_migrations::{EmbeddedMigrations, MigrationHarness as _, embed_migrations};
use dotenvy::dotenv;
use http::{
    HeaderMap, HeaderName, HeaderValue,
    header::{CACHE_CONTROL, CONNECTION, COOKIE, HOST, TRANSFER_ENCODING, USER_AGENT},
};
use tokio::task::JoinSet;
use tokio_rustls::rustls::{
    RootCertStore, ServerConfig,
    pki_types::{CertificateDer, PrivateKeyDer, pem::PemObject},
    server::WebPkiClientVerifier,
};
use tower::ServiceExt as _;
use tower_http::{
    cors::CorsLayer,
    trace::{DefaultMakeSpan, TraceLayer},
};
use tracing::{Level, info};

use crate::{
    auth::{Account, AuthenticationMethod},
    config::{AppDefinition, Config},
    infra::DatabaseConnector,
    mtls::MtlsExtension,
    sessions::{SessionHandle, SessionLayer},
};

#[derive(Debug, Clone)]
struct BackendState {
    definition: Option<AppDefinition>,
    authentication_methods: Vec<Arc<dyn AuthenticationMethod + Send + Sync>>,
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
    providers: HashMap<String, BackendState>,
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

        let account = match Account::from_request_parts(&mut parts, &()).await {
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
        match account {
            Account::User(user) => {
                proxy_headers.insert("X-User-Id", HeaderValue::from_str(user.id()).unwrap());
                proxy_headers.insert(
                    "X-Auth-Method",
                    HeaderValue::from_str(user.auth_method()).unwrap(),
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
            }
            Account::Machine(machine) => {
                proxy_headers.insert(
                    "X-Auth-Method",
                    HeaderValue::from_str(machine.auth_method()).unwrap(),
                );
                proxy_headers.insert(
                    "X-Ramona-Hostname",
                    HeaderValue::from_str(machine.hostname()).unwrap(),
                );
            }
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

#[axum::debug_handler]
async fn get_authorize(
    extract::Extension(state): extract::Extension<AppState>,
    session: extract::Extension<SessionHandle>,
    request: extract::Request,
) -> (StatusCode, HeaderMap, String) {
    let session_data = session.data().await;

    // TODO 404 if it's missing
    let provider = state
        .providers
        .get(&session_data.in_progress_provider.unwrap())
        .unwrap();

    let (mut request_parts, _request_body) = request.into_parts();
    for method in &provider.authentication_methods {
        match method.authenticate_redirected(&mut request_parts).await {
            Ok(uri) => {
                let mut headers = HeaderMap::new();
                headers.insert(LOCATION, HeaderValue::from_str(&uri.to_string()).unwrap());

                return (StatusCode::FOUND, headers, String::new());
            }
            Err(_) => todo!(),
        }
    }

    (
        StatusCode::BAD_REQUEST,
        HeaderMap::new(),
        "no matching provider found".to_string(),
    )
}

pub const MIGRATIONS: EmbeddedMigrations = embed_migrations!("migrations/");

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt().init();
    let _ = dotenv();
    rustls::crypto::aws_lc_rs::default_provider()
        .install_default()
        .unwrap();

    info!(
        git_hash = env!("RAMONA_GIT_HASH"),
        package = env!("CARGO_PKG_NAME"),
        "initializing"
    );

    let config = config::load().unwrap();
    let database_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    PgConnection::establish(&database_url)
        .expect("failed to connect to the database")
        .run_pending_migrations(MIGRATIONS)
        .unwrap();

    let backend_http_client = ::reqwest::ClientBuilder::new()
        .redirect(::reqwest::redirect::Policy::none())
        .build()
        .unwrap();

    let mut providers = HashMap::new();
    for (host, app_definition) in &config.apps {
        let mut authentication_methods = vec![];
        for authentication_method in &app_definition.auth_methods {
            let authentication_method: Arc<dyn AuthenticationMethod + Send + Sync> =
                match authentication_method {
                    config::AuthMethod::OAuth(oauth_configuration) => Arc::new(
                        auth::oauth::OAuth::new(
                            oauth_configuration.required_entitlement.clone(),
                            app_definition.base_url.parse().unwrap(),
                            config.base_url.parse().unwrap(),
                            config.api.oauth.clone(),
                        )
                        .await,
                    ),
                    config::AuthMethod::Token => Arc::new(auth::token::Token::new(
                        DatabaseConnector::new(database_url.clone()),
                    )),
                    config::AuthMethod::MTls => Arc::new(auth::mtls::MTls::new()),
                };

            authentication_methods.push(authentication_method);
        }

        providers.insert(
            host.to_string(),
            BackendState {
                authentication_methods,
                definition: Some(app_definition.clone()),
            },
        );
    }

    providers.insert(
        config.hostname.clone(),
        BackendState {
            authentication_methods: vec![Arc::new(
                auth::oauth::OAuth::new(
                    config.api.oauth_config.required_entitlement.clone(),
                    config.base_url.parse().unwrap(),
                    config.base_url.parse().unwrap(),
                    config.api.oauth.clone(),
                )
                .await,
            )],
            definition: None,
        },
    );

    let cookie_domain = config.cookie_domain.clone();

    let state = AppState {
        config: config.clone(),
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

    let mut servers = JoinSet::new();
    let http_server = axum_server::bind(SocketAddr::from(([0, 0, 0, 0], 3000))).serve(
        router
            .clone()
            .layer(Extension(MtlsExtension::NotAuthenticated))
            .into_make_service(),
    );
    servers.spawn(http_server);

    if let Some(ref mtls_config) = config.mtls {
        let mut client_root_cert_store = RootCertStore::empty();
        for root in &mtls_config.client_roots {
            client_root_cert_store
                .add(CertificateDer::from_pem_file(root).unwrap())
                .unwrap();
        }
        let client_cert_verifier_builder =
            WebPkiClientVerifier::builder(Arc::new(client_root_cert_store));

        let tls_config = ServerConfig::builder()
            .with_client_cert_verifier(client_cert_verifier_builder.build().unwrap())
            .with_single_cert(
                mtls_config
                    .server_chain
                    .iter()
                    .map(|x| CertificateDer::from_pem_file(x).unwrap())
                    .collect(),
                PrivateKeyDer::from_pem_file(&mtls_config.server_key).unwrap(),
            )
            .unwrap();

        let mtls_server = axum_server::bind_rustls(
            SocketAddr::from(([0, 0, 0, 0], 3001)),
            RustlsConfig::from_config(Arc::new(tls_config)),
        )
        .serve(
            router
                .layer(Extension(MtlsExtension::Authenticated))
                .into_make_service(),
        );

        servers.spawn(mtls_server);
    }

    for result in servers.join_all().await {
        result.unwrap();
    }
}
