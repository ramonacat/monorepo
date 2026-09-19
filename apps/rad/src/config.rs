use std::path::PathBuf;

use serde::Deserialize;

#[derive(Debug, Deserialize)]
#[serde(tag = "endpoint")]
pub enum WireguardEndpoint {
    Disabled,
    Auto,
    Specified { host: String, port: u16 },
}

#[derive(Debug, Deserialize)]
pub struct Configuration {
    pub certificate: PathBuf,
    pub key: PathBuf,
    pub wireguard: WireguardEndpoint,
}
