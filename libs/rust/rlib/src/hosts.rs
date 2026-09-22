use std::net::SocketAddr;

use chrono::{DateTime, Utc};
use ipnet::IpNet;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct UDPEndpoint(IpNet, u16);

impl UDPEndpoint {
    pub fn new(address: IpNet, port: u16) -> Self {
        Self(address, port)
    }

    pub fn adddress(&self) -> IpNet {
        self.0
    }

    pub fn port(&self) -> u16 {
        self.1
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct WireguardEndpoint {
    pub public_key: String,
    pub endpoint: Option<SocketAddr>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Hash, PartialEq, Eq)]
pub struct HostAddress {
    pub address: IpNet,
    pub interface: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ConnectivityState {
    pub addresses: Vec<HostAddress>,
    pub wireguard: Option<WireguardEndpoint>,
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

    pub connectivity: ConnectivityState,
    pub nix_closure_state: Option<NixClosureState>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ClosureUpdate {
    pub latest_closure: Option<String>,
    pub current_closure: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PostHostStateRequest {
    pub connectivity: ConnectivityState,
    pub closure: Option<ClosureUpdate>,
}
