use std::{collections::HashMap, net::SocketAddr};

use serde::{Deserialize, Serialize};

pub const WIREGUARD_PORT_DEFAULT: u16 = 51820;

#[derive(Debug, Serialize, Deserialize)]
pub struct WireguardEndpoint {
    pub public_key: String,
    pub endpoint: Option<SocketAddr>,
}

#[derive(Debug, Serialize)]
pub struct GetWireguardEndpointsResponse {
    // TODO add a `Hostname` type and replace the string here with it
    pub endpoints: HashMap<String, WireguardEndpoint>,
}
