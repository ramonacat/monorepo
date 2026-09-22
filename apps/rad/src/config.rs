use anyhow::Context;
use std::fs;
use std::path::PathBuf;

use serde::Deserialize;

#[derive(Debug, Deserialize)]
#[serde(tag = "endpoint")]
pub enum WireguardEndpoint {
    Disabled,
    Auto,
    Specified { host: String, port: u16 },
}

fn default_key_path() -> PathBuf {
    "/var/ramona/wireguard.key".parse().unwrap()
}

#[derive(Debug, Deserialize)]
pub struct Wireguard {
    #[serde(flatten)]
    pub endpoint: WireguardEndpoint,
    // TODO remove the default and put this in the configs explicitly
    #[serde(default = "default_key_path")]
    pub key_path: PathBuf,
}

#[derive(Debug, Deserialize)]
pub struct Configuration {
    pub certificate: PathBuf,
    pub key: PathBuf,
    pub wireguard: Wireguard,
}

pub fn read() -> Result<Configuration, anyhow::Error> {
    let path = crate::env::config_path()?;
    let file = fs::File::open(&path)
        .with_context(|| format!("failed to open the config file {:?} for reading", path))?;
    let config: Configuration = serde_json::from_reader(file)
        .with_context(|| format!("failed to parse config file {:?}", path))?;

    Ok(config)
}
