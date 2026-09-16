pub mod oauth;
pub mod token;

use std::fmt::Debug;
use std::{collections::HashSet, error::Error};

use async_trait::async_trait;
use chrono::{DateTime, Utc};
use http::Uri;
use thiserror::Error;

#[derive(Debug)]
pub struct User {
    id: String,
    name: Option<String>,
    entitlements: HashSet<String>,
    auth_method: &'static str,
    expiration: Option<DateTime<Utc>>,
}

impl User {
    #[deprecated]
    pub fn new(
        id: String,
        name: Option<String>,
        entitlements: HashSet<String>,
        auth_method: &'static str,
        expiration: Option<DateTime<Utc>>,
    ) -> Self {
        Self {
            id,
            name,
            entitlements,
            auth_method,
            expiration,
        }
    }

    pub fn id(&self) -> &str {
        &self.id
    }

    pub fn name(&self) -> Option<&str> {
        self.name.as_deref()
    }

    pub fn auth_method(&self) -> &'static str {
        self.auth_method
    }

    pub fn expiration(&self) -> Option<&DateTime<Utc>> {
        self.expiration.as_ref()
    }

    pub fn has_entitlement(&self, entitlement: &str) -> bool {
        self.entitlements.contains(entitlement)
    }
}

#[derive(Debug)]
pub struct Machine {
    name: String,
}

#[derive(Debug)]
pub enum Account {
    User(User),
    Machine(Machine),
}

#[derive(Debug, Error)]
pub enum AuthenticationError {
    #[error("not authenticated")]
    NotAuthenticated { redirect: Option<Uri> },

    #[error("not authorized")]
    NotAuthorized,

    #[error("failed: {0}")]
    Failed(Box<dyn Error>),
}

pub enum AuthenticateRedirectedError {
    NoMatch,
    BadRequest,
    Failed(Box<dyn Error>),
}

#[async_trait]
pub trait AuthenticationMethod: Debug {
    async fn authenticate(
        &self,
        request_parts: &mut http::request::Parts,
    ) -> Result<Account, AuthenticationError>;

    async fn authenticate_redirected(
        &self,
        request_parts: &mut http::request::Parts,
    ) -> Result<Uri, AuthenticateRedirectedError>;
}
