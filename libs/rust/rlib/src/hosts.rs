use std::net::IpAddr;

use chrono::{DateTime, Utc};
use ipnet::IpNet;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Eq, PartialEq, Clone)]
#[serde(transparent)]
pub struct Hostname(String);

impl Hostname {
    pub fn new(value: String) -> Self {
        Self(value)
    }

    pub fn first_label(&self) -> &str {
        self.0.split_at(self.0.find('.').unwrap_or(self.0.len())).0
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct NixClosureState {
    pub current_closure: Option<String>,
    pub current_closure_updated_at: Option<DateTime<Utc>>,
    pub latest_closure: Option<String>,
    pub latest_closure_updated_at: Option<DateTime<Utc>>,
    pub outdated: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct HostState {
    pub hostname: String,

    // TODO these fields were moved into nix_closure_state, but they need to stay here until all the
    // update scripts, pipelines and grafana dashboard that depend on them are updated
    pub current_closure: Option<String>,
    pub current_closure_updated_at: Option<DateTime<Utc>>,
    pub latest_closure: Option<String>,
    pub latest_closure_updated_at: Option<DateTime<Utc>>,
    pub outdated: bool,

    pub nix_closure_state: Option<NixClosureState>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Hash, PartialEq, Eq)]
pub struct HostAddress {
    pub address: IpNet,
    pub interface: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct WireguardState {
    pub listen_addresses: Vec<IpAddr>,
    pub available_ports: Vec<u16>,
    pub public_key: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct NetworkingState {
    pub addresses: Vec<HostAddress>,
    pub wireguard: Option<WireguardState>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct NixosState {
    pub current_closure: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PostHostStateRequest {
    // TODO rename closure -> nixos
    pub closure: Option<NixosState>,
    pub networking: Option<NetworkingState>,
}
