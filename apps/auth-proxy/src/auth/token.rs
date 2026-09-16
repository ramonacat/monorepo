use std::collections::HashSet;

use crate::{
    auth::{AuthenticateRedirectedError, AuthenticationError, User},
    infra::DatabaseConnector,
    oauth::RamonaTokenSessionData,
    sessions::SessionHandle,
};
use async_trait::async_trait;
use axum::extract;
use axum::extract::FromRequestParts;
use chrono::Utc;
use diesel::{
    BoolExpressionMethods as _, ExpressionMethods as _, OptionalExtension as _, QueryDsl as _,
};
use diesel_async::RunQueryDsl as _;
use http::{Uri, request};
use openidconnect::{AuthorizationCode, PkceCodeVerifier};
use tracing::info;

use crate::auth::AuthenticationMethod;

use serde::Deserialize;

#[derive(Debug, Deserialize)]
struct TokenQuery {
    pub rtoken: String,
}

#[derive(Debug)]
pub struct Token {
    database: DatabaseConnector,
}

impl Token {
    pub fn new(database: DatabaseConnector) -> Self {
        Self { database }
    }
}

#[async_trait]
impl AuthenticationMethod for Token {
    async fn authenticate(
        &self,
        request_parts: &mut http::request::Parts,
    ) -> Result<super::Account, super::AuthenticationError> {
        let query = extract::Query::<TokenQuery>::from_request_parts(request_parts, &()).await;
        let extract::Extension(session) =
            extract::Extension::<SessionHandle>::from_request_parts(request_parts, &())
                .await
                .unwrap();
        let ramona_token_state = session.data().await.token;

        let token_value = query
            .ok()
            .map(|y| y.rtoken.clone())
            .or_else(|| ramona_token_state.as_ref().map(|x| x.token().to_string()));

        let Some(token_value) = token_value else {
            return Err(AuthenticationError::NotAuthenticated { redirect: None });
        };

        let mut connection = self.database.connect().await;

        let the_token = {
            use crate::schema::tokens::dsl::*;

            let the_token: Option<crate::models::Token> = tokens
                .filter(value.eq(&token_value).and(expiration.gt(Utc::now())))
                .first(&mut connection)
                .await
                .optional()
                .unwrap();

            the_token
        };

        let Some(token) = the_token else {
            return Err(AuthenticationError::NotAuthenticated { redirect: None });
        };
        info!(id = ?token.id, "token authentication passed");

        if ramona_token_state.is_none() {
            session
                .update(|s| {
                    s.token = Some(RamonaTokenSessionData::new(token_value.clone()));
                })
                .await
        }

        Ok(crate::auth::Account::User(User::new(
            format!("token:{}", token.id),
            None,
            HashSet::new(),
            "token",
            Some(token.expiration),
        )))
    }

    async fn authenticate_redirected(
        &self,
        _request_parts: &mut http::request::Parts,
    ) -> Result<Uri, AuthenticateRedirectedError> {
        Err(AuthenticateRedirectedError::NoMatch)
    }
}
