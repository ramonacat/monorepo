use async_trait::async_trait;
use axum::extract::{self, FromRequestParts as _};
use http::Uri;
use openidconnect::{
    AuthorizationCode, CsrfToken, Nonce, PkceCodeChallenge, PkceCodeVerifier, Scope,
    core::CoreAuthenticationFlow,
};
use serde::Deserialize;
use tracing::info;

use crate::{
    OAuth2Client,
    auth::{AuthenticateRedirectedError, AuthenticationError, AuthenticationMethod, User},
    oauth::OAuthSessionData,
    sessions::SessionHandle,
};

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
    pub fn new(
        required_entitlement: Option<String>,
        oidc_http_client: openidconnect::reqwest::Client,
        client: OAuth2Client,
        app_base_url: Uri,
    ) -> Self {
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
