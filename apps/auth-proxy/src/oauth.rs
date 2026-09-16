use crate::auth::Account;
use crate::auth::AuthenticationError;
use crate::auth::User;

use crate::AppState;
use axum::extract;
use axum::{body::Body, extract::FromRequestParts};
use http::header::LOCATION;
use http::{Response, StatusCode};
use openidconnect::{CsrfToken, Nonce};
use serde::Deserialize;
use serde::Serialize;
use tracing::error;

use crate::Hostname;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct RamonaTokenSessionData {
    token: String,
}

impl RamonaTokenSessionData {
    pub fn new(token: String) -> Self {
        Self { token }
    }

    pub fn token(&self) -> &str {
        &self.token
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
        // TODO throw a 404 instead of panicking
        let provider = state.providers.get(&host).unwrap();

        for authentication_method in &provider.authentication_methods {
            let response = authentication_method.authenticate(parts).await;

            match response {
                Ok(account) => match account {
                    Account::User(user) => return Ok(user),
                    Account::Machine(_machine) => todo!(),
                },
                Err(error) => match error {
                    AuthenticationError::NotAuthenticated { redirect } => {
                        let mut response = Response::new(Body::default());

                        if let Some(redirect_url) = redirect {
                            *response.status_mut() = StatusCode::FOUND;
                            response
                                .headers_mut()
                                .insert(LOCATION, redirect_url.to_string().parse().unwrap());

                            return Err(response);
                        } else {
                            continue;
                        }
                    }
                    AuthenticationError::NotAuthorized => {
                        let mut response = Response::new(Body::default());

                        *response.status_mut() = StatusCode::UNAUTHORIZED;

                        return Err(response);
                    }
                    AuthenticationError::Failed(error) => {
                        error!(error);
                        panic!("{}", error);
                    }
                },
            }
        }

        let mut response = Response::new(Body::empty());
        *response.status_mut() = StatusCode::UNAUTHORIZED;

        Err(response)
    }
}
