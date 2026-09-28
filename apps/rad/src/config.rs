use anyhow::Context;
use rlib::config::SecretValue;
use std::fs;
use std::net::SocketAddr;
use std::path::PathBuf;

use serde::Deserialize;

#[derive(Debug, Deserialize)]
#[serde(tag = "endpoint")]
pub enum WireguardEndpoint {
    InitiatorOnly,
    Auto,
    Specified { host: String, port: u16 },
}

#[derive(Debug, Deserialize)]
pub struct Wireguard {
    #[serde(flatten)]
    pub endpoint: WireguardEndpoint,
    pub key_path: PathBuf,
}

#[derive(Debug, Deserialize)]
pub struct Mikrotik {
    pub endpoint: SocketAddr,
    pub username: String,
    pub password: SecretValue<String>,
}

#[derive(Debug, Deserialize)]
pub struct Configuration {
    pub certificate: PathBuf,
    pub key: PathBuf,
    pub wireguard: Option<Wireguard>,
    pub mikrotik: Option<Mikrotik>,
}

pub fn read() -> Result<Configuration, anyhow::Error> {
    let path = crate::env::config_path()?;
    let file = fs::File::open(&path)
        .with_context(|| format!("failed to open the config file {:?} for reading", path))?;
    let config: Configuration = serde_json::from_reader(file)
        .with_context(|| format!("failed to parse config file {:?}", path))?;

    Ok(config)
}
