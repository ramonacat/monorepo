use std::{
    collections::HashMap,
    env::{self, VarError},
    fs, io,
};

use serde::{Deserialize, Serialize};
use thiserror::Error;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct OAuthConfiguration {
    pub client_id: String,
    pub client_secret: String,
    pub oidc_issuer_url: String,
    pub required_entitlement: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AuthMethodOAuth {
    pub required_entitlement: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(tag = "type", content = "config")]
pub enum AuthMethod {
    OAuth(AuthMethodOAuth),
    Token,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AppDefinition {
    pub base_url: String,
    pub backend: String,
    pub auth_methods: Vec<AuthMethod>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ApiConfig {
    pub oauth: OAuthConfiguration,
    pub oauth_config: AuthMethodOAuth,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub hostname: String,
    pub base_url: String,
    /// this must be a common subdomain that all of the cookies use
    pub cookie_domain: String,

    /// must be crypto-safe random 64 hex bytes
    /// can be generated with `openssl rand -hex 64`
    pub session_key: String,
    pub apps: HashMap<String, AppDefinition>,
    pub api: ApiConfig,
}

#[derive(Debug, Error)]
pub enum Error {
    #[error("env var: {0}")]
    Var(#[from] VarError),

    #[error("io: {0}")]
    Io(#[from] io::Error),

    #[error("subst json: {0}")]
    Subst(#[from] subst::json::Error),
}

pub fn load() -> Result<Config, Error> {
    let config_path = env::var("RAMONA_RED_CONFIG_PATH")?;

    Ok(subst::json::from_slice(
        &fs::read(config_path)?,
        &subst::Env,
    )?)
}
