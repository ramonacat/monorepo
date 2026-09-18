use std::str::FromStr as _;

use async_trait::async_trait;
use axum::extract::{self, FromRequestParts as _};
use http::Uri;
use openidconnect::{
    AuthorizationCode, ClientId, ClientSecret, CsrfToken, IssuerUrl, Nonce, PkceCodeChallenge,
    PkceCodeVerifier, RedirectUrl, Scope,
    core::{CoreAuthenticationFlow, CoreProviderMetadata},
};
use serde::{Deserialize, Serialize};
use tracing::info;

use crate::{
    auth::{AuthenticateRedirectedError, AuthenticationError, AuthenticationMethod, User},
    config::OAuthConfiguration,
    sessions::SessionHandle,
};
use openidconnect::{
    EmptyExtraTokenFields, EndpointMaybeSet, EndpointNotSet, EndpointSet, IdToken, IdTokenFields,
    StandardErrorResponse, StandardTokenResponse,
    core::{
        CoreAuthDisplay, CoreAuthPrompt, CoreErrorResponseType, CoreGenderClaim, CoreJsonWebKey,
        CoreJweContentEncryptionAlgorithm, CoreJwsSigningAlgorithm, CoreRevocableToken,
        CoreRevocationErrorResponse, CoreTokenIntrospectionResponse, CoreTokenType,
    },
};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct OAuthSessionData {
    csrf_token: CsrfToken,
    pkce_verifier: String,
    nonce: Nonce,
    return_url: String,
    id_token: Option<OAuth2IdToken>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
struct AdditionalClaims {
    pub entitlements: Vec<String>,
}

impl openidconnect::AdditionalClaims for AdditionalClaims {}

type OAuth2IdToken = IdToken<
    AdditionalClaims,
    CoreGenderClaim,
    CoreJweContentEncryptionAlgorithm,
    CoreJwsSigningAlgorithm,
>;
type OAuth2IdTokenFields = IdTokenFields<
    AdditionalClaims,
    EmptyExtraTokenFields,
    CoreGenderClaim,
    CoreJweContentEncryptionAlgorithm,
    CoreJwsSigningAlgorithm,
>;
type OAuth2TokenResponse = StandardTokenResponse<OAuth2IdTokenFields, CoreTokenType>;

type OAuth2Client = openidconnect::Client<
    AdditionalClaims,
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

#[derive(Debug, Deserialize)]
struct AuthenticateRedirectedQuery {
    code: String,
    state: String,
}

#[derive(Debug)]
pub struct OAuth {
    required_entitlement: Option<String>,

    client: OAuth2Client,
    oidc_http_client: openidconnect::reqwest::Client,
    app_base_url: Uri,
}

#[async_trait]
impl AuthenticationMethod for OAuth {
    async fn authenticate(
        &self,
        request_parts: &mut http::request::Parts,
    ) -> Result<super::Account, AuthenticationError> {
        let extract::Extension(session): extract::Extension<SessionHandle> =
            extract::Extension::from_request_parts(request_parts, &())
                .await
                .map_err(|x| AuthenticationError::Failed(Box::new(x)))?;
        let oauth_session_state = session.data().await.oauth;
        if let Some(oauth_session_state) = oauth_session_state
            && let Some(user) = self.validate_token(&oauth_session_state)
        {
            info!(?user, "user found");

            if let Some(entitlement) = self.required_entitlement.as_deref()
                && !user.has_entitlement(entitlement)
            {
                return Err(AuthenticationError::NotAuthorized);
            }

            return Ok(crate::auth::Account::User(user));
        }

        let (pkce_challenge, pkce_verifier) = PkceCodeChallenge::new_random_sha256();

        let (auth_url, csrf_token, nonce) = self
            .client
            .authorize_url(
                CoreAuthenticationFlow::AuthorizationCode,
                CsrfToken::new_random,
                Nonce::new_random,
            )
            .set_pkce_challenge(pkce_challenge)
            .add_scope(Scope::new("entitlements".to_string()))
            .url();

        let extract::OriginalUri(original_uri) =
            extract::OriginalUri::from_request_parts(request_parts, &())
                .await
                .unwrap();

        session
            .update(|data| {
                data.in_progress_provider =
                    Some(self.app_base_url.authority().unwrap().host().to_string());
                data.oauth = Some(OAuthSessionData {
                    csrf_token,
                    pkce_verifier: pkce_verifier.secret().clone(),
                    nonce,
                    return_url: format!(
                        "{}{}",
                        self.app_base_url,
                        original_uri
                            .path_and_query()
                            .map(|x| x.to_string())
                            .unwrap_or_default()
                            .strip_prefix('/')
                            .unwrap_or_default()
                    ),
                    id_token: None,
                })
            })
            .await;

        Err(AuthenticationError::NotAuthenticated {
            redirect: Some(auth_url.to_string().parse().unwrap()),
        })
    }

    async fn authenticate_redirected(
        &self,
        request_parts: &mut http::request::Parts,
    ) -> Result<Uri, AuthenticateRedirectedError> {
        let session = extract::Extension::<SessionHandle>::from_request_parts(request_parts, &())
            .await
            .unwrap();
        let extract::Query(query) =
            extract::Query::<AuthenticateRedirectedQuery>::from_request_parts(request_parts, &())
                .await
                .unwrap();

        let mut oauth_session_state = session.data().await.oauth.unwrap();
        if &query.state != oauth_session_state.csrf_token.secret() {
            return Err(AuthenticateRedirectedError::BadRequest);
        }
        let return_url = oauth_session_state.return_url.parse().unwrap();

        let pkce_verifier = PkceCodeVerifier::new(oauth_session_state.pkce_verifier.clone());
        let token_response = self
            .client
            .exchange_code(AuthorizationCode::new(query.code))
            .unwrap()
            .set_pkce_verifier(pkce_verifier)
            .request_async(&self.oidc_http_client)
            .await
            .unwrap();

        oauth_session_state.id_token =
            Some(token_response.extra_fields().id_token().unwrap().clone());
        session
            .update(|s| {
                s.oauth = Some(oauth_session_state);
                s.in_progress_provider = None;
            })
            .await;

        Ok(return_url)
    }
}

impl OAuth {
    pub async fn new(
        required_entitlement: Option<String>,
        app_base_url: Uri,
        base_url: Uri,
        oauth_config: OAuthConfiguration,
    ) -> Self {
        let oidc_http_client = openidconnect::reqwest::ClientBuilder::new()
            .redirect(openidconnect::reqwest::redirect::Policy::none())
            .build()
            .unwrap();

        let provider_metadata = CoreProviderMetadata::discover_async(
            IssuerUrl::new(oauth_config.oidc_issuer_url.clone()).unwrap(),
            &oidc_http_client,
        )
        .await
        .unwrap();

        let redirect_uri = http::Uri::from_str(&format!("{}authorize", base_url)).unwrap();

        let client = OAuth2Client::from_provider_metadata(
            provider_metadata.clone(),
            ClientId::new(oauth_config.client_id.clone()),
            Some(ClientSecret::new(oauth_config.client_secret.clone())),
        )
        .set_redirect_uri(RedirectUrl::new(redirect_uri.to_string()).unwrap());
        Self {
            required_entitlement,
            oidc_http_client,
            client,
            app_base_url,
        }
    }

    fn validate_token(&self, state: &OAuthSessionData) -> Option<User> {
        let claims = state
            .id_token
            .as_ref()?
            .claims(&self.client.id_token_verifier(), &state.nonce);

        //TODO do a special case for expired token (use the refresh token instead of going through the
        //whole auth process again)
        claims.ok().map(|x| {
            User::new(
                x.subject().to_string(),
                x.name().and_then(|x| x.get(None)).map(|x| x.to_string()),
                x.additional_claims()
                    .entitlements
                    .clone()
                    .into_iter()
                    .collect(),
                "oauth",
                None,
            )
        })
    }
}
