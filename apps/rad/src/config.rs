use anyhow::Context;
use ipnet::IpNet;
use rlib::config::SecretValue;
use std::fs;
use std::net::SocketAddr;
use std::path::PathBuf;

use serde::Deserialize;

use crate::state::StateManager;

#[derive(Debug, Deserialize)]
#[serde(tag = "endpoint")]
pub enum WireguardEndpoint {
    InitiatorOnly,
    Auto {
        available_ports: Option<Vec<u16>>,
    },
    Specified {
        host: String,
        available_ports: Option<Vec<u16>>,
    },
}

#[derive(Debug, Deserialize)]
pub struct Wireguard {
    #[serde(flatten)]
    pub endpoint: WireguardEndpoint,
    pub key_file: PathBuf,
}

#[derive(Debug, Deserialize)]
pub struct MikrotikWireguard {
    #[serde(flatten)]
    #[allow(
        unused,
        reason = "TODO this needs to actually be used to allow mikrotik to be a responder"
    )]
    pub endpoint: WireguardEndpoint,
    pub key_path: PathBuf,
}

#[derive(Debug, Deserialize)]
pub struct Mikrotik {
    pub endpoint: SocketAddr,
    pub username: String,
    pub password: SecretValue<String>,
    pub wireguard: MikrotikWireguard,
}

#[derive(Debug, Deserialize, Clone, Copy)]
pub struct RoutingNetwork {
    pub cidr: IpNet,
    pub cost: u32,
}

#[derive(Debug, Deserialize)]
pub struct Routing {
    pub networks: Vec<RoutingNetwork>,
    pub frr_config: PathBuf,
}

#[derive(Debug, Deserialize)]
pub struct Configuration {
    pub certificate: PathBuf,
    pub key: PathBuf,
    pub wireguard: Option<Wireguard>,
    pub mikrotik: Option<Mikrotik>,
    pub routing: Option<Routing>,
    // TODO add defaults for paths so they don't all have to be configured?
    pub state: PathBuf,
}

impl Configuration {
    pub fn state(&self) -> StateManager {
        StateManager::new(&self.state)
    }
}

pub fn read() -> Result<Configuration, anyhow::Error> {
    let path = crate::env::config_path()?;
    let file = fs::File::open(&path)
        .with_context(|| format!("failed to open the config file {:?} for reading", path))?;
    let config: Configuration = serde_json::from_reader(file)
        .with_context(|| format!("failed to parse config file {:?}", path))?;

    Ok(config)
}
