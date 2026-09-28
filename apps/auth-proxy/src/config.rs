use std::{collections::HashMap, path::PathBuf};

use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct OAuthConfiguration {
    pub client_id: String,
    pub client_secret: String,
    pub oidc_issuer_url: String,
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
    MTls,
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
    pub mtls: Option<MtlsConfig>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MtlsConfig {
    pub client_roots: Vec<PathBuf>,
    pub server_chain: Vec<PathBuf>,
    pub server_key: PathBuf,
}
