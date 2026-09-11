use crate::OAuth2IdToken;
use crate::sessions::SessionHandle;
use std::collections::HashSet;
use std::fmt::Display;

use crate::AppState;
use crate::OAuth2Client;
use crate::tokens::TokenQuery;
use axum::extract;
use axum::{body::Body, extract::FromRequestParts};
use chrono::DateTime;
use chrono::Utc;
use diesel::BoolExpressionMethods;
use diesel::ExpressionMethods;
use diesel::OptionalExtension;
use diesel::query_dsl::methods::FilterDsl;
use diesel_async::RunQueryDsl;
use http::header::LOCATION;
use http::{Response, StatusCode};
use openidconnect::Scope;
use openidconnect::{CsrfToken, Nonce, PkceCodeChallenge, core::CoreAuthenticationFlow};
use serde::Deserialize;
use serde::Serialize;
use tracing::info;

use crate::Hostname;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct OAuthSessionData {
    pub csrf_token: CsrfToken,
    pub pkce_verifier: String,
    pub nonce: Nonce,
    pub return_url: String,
    pub id_token: Option<OAuth2IdToken>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct RamonaTokenSessionData {
    token: String,
}

#[derive(Debug, Clone, Copy)]
pub enum AuthMethodKind {
    Token,
    OAuth,
}

impl Display for AuthMethodKind {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "{}",
            match self {
                AuthMethodKind::Token => "token",
                AuthMethodKind::OAuth => "oauth",
            }
        )
    }
}

#[derive(Debug)]
pub struct User {
    id: String,
    name: Option<String>,
    entitlements: HashSet<String>,
    auth_method: AuthMethodKind,
    expiration: Option<DateTime<Utc>>,
}

impl User {
    pub fn id(&self) -> &str {
        &self.id
    }

    pub fn name(&self) -> Option<&str> {
        self.name.as_deref()
    }

    pub fn auth_method(&self) -> AuthMethodKind {
        self.auth_method
    }

    pub fn expiration(&self) -> Option<&DateTime<Utc>> {
        self.expiration.as_ref()
    }

    pub fn is_admin(&self) -> bool {
        self.entitlements.contains("admin")
    }
}

impl FromRequestParts<()> for User {
    type Rejection = Response<Body>;

    async fn from_request_parts(
        parts: &mut http::request::Parts,
        state: &(),
    ) -> Result<Self, Self::Rejection> {
        let extract::Extension(state): extract::Extension<AppState> =
            extract::Extension::from_request_parts(parts, state)
                .await
                .unwrap();
        let Hostname(host) = Hostname::from_request_parts(parts, &state).await.unwrap();
        let extract::Extension(session) =
            extract::Extension::<SessionHandle>::from_request_parts(parts, &state)
                .await
                .unwrap();
        // TODO throw a 404 instead of panicking
        let provider = state.providers.get(&host).unwrap();

        for authentication_method in &provider.authentication_methods {
            match authentication_method {
                crate::AuthenticationMethodState::OAuth {
                    client,
                    required_entitlement,
                } => {
                    let oauth_session_state = session.data().await.oauth;
                    if let Some(oauth_session_state) = oauth_session_state
                        && let Some(user) = validate_token(&oauth_session_state, client)
                    {
                        info!(?user, "user found");

                        if let Some(entitlement) = required_entitlement.as_deref()
                            && !user.entitlements.contains(entitlement)
                        {
                            let mut response = Response::new(Body::empty());
                            *response.status_mut() = StatusCode::UNAUTHORIZED;

                            return Err(response);
                        }

                        return Ok(user);
                    }

                    let (pkce_challenge, pkce_verifier) = PkceCodeChallenge::new_random_sha256();

                    let (auth_url, csrf_token, nonce) = client
                        .authorize_url(
                            CoreAuthenticationFlow::AuthorizationCode,
                            CsrfToken::new_random,
                            Nonce::new_random,
                        )
                        .set_pkce_challenge(pkce_challenge)
                        .add_scope(Scope::new("entitlements".to_string()))
                        .url();

                    let extract::OriginalUri(original_uri) =
                        extract::OriginalUri::from_request_parts(parts, &state)
                            .await
                            .unwrap();

                    session
                        .update(|data| {
                            data.oauth = Some(OAuthSessionData {
                                csrf_token,
                                pkce_verifier: pkce_verifier.secret().clone(),
                                nonce,
                                return_url: format!(
                                    "{}{}",
                                    provider.base_url,
                                    original_uri
                                        .path_and_query()
                                        .map(|x| x.to_string())
                                        .unwrap_or_default()
                                ),
                                id_token: None,
                            })
                        })
                        .await;

                    let mut response = Response::new(Body::default());
                    *response.status_mut() = StatusCode::FOUND;
                    response
                        .headers_mut()
                        .insert(LOCATION, auth_url.to_string().parse().unwrap());

                    return Err(response);
                }
                crate::AuthenticationMethodState::Token => {
                    let query = extract::Query::<TokenQuery>::from_request_parts(parts, &()).await;
                    let ramona_token_state = session.data().await.token;

                    let token_value = query
                        .ok()
                        .map(|y| y.rtoken.clone())
                        .or_else(|| ramona_token_state.as_ref().map(|x| x.token.clone()));

                    if let Some(token_value) = token_value {
                        let mut connection = state.database.connect().await;

                        {
                            use crate::schema::tokens::dsl::*;

                            let the_token: Option<crate::models::Token> = tokens
                                .filter(value.eq(&token_value).and(expiration.gt(Utc::now())))
                                .first(&mut connection)
                                .await
                                .optional()
                                .unwrap();

                            if let Some(token) = the_token {
                                info!(id = ?token.id, "token authentication passed");

                                if ramona_token_state.is_none() {
                                    session
                                        .update(|s| {
                                            s.token = Some(RamonaTokenSessionData {
                                                token: token_value.clone(),
                                            })
                                        })
                                        .await
                                }

                                return Ok(User {
                                    id: format!("token:{}", token.id),
                                    name: None,
                                    entitlements: HashSet::new(),
                                    auth_method: AuthMethodKind::Token,
                                    expiration: Some(token.expiration),
                                });
                            } else {
                                session
                                    .update(|s| {
                                        s.token = None;
                                    })
                                    .await;
                            }
                        }
                    }
                }
            }
        }

        let mut response = Response::new(Body::empty());
        *response.status_mut() = StatusCode::UNAUTHORIZED;

        Err(response)
    }
}

fn validate_token(state: &OAuthSessionData, client: &OAuth2Client) -> Option<User> {
    let claims = state
        .id_token
        .as_ref()?
        .claims(&client.id_token_verifier(), &state.nonce);

    //TODO do a special case for expired token (use the refresh token instead of going through the
    //whole auth process again)
    claims.ok().map(|x| User {
        id: x.subject().to_string(),
        name: x.name().and_then(|x| x.get(None)).map(|x| x.to_string()),
        entitlements: x
            .additional_claims()
            .entitlements
            .clone()
            .into_iter()
            .collect(),
        auth_method: AuthMethodKind::OAuth,
        expiration: None,
    })
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AdditionalClaims {
    pub entitlements: Vec<String>,
}

impl openidconnect::AdditionalClaims for AdditionalClaims {}
