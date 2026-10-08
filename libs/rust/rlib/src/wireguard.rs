use crate::hosts::Hostname;
use ipnet::IpNet;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Serialize, Deserialize)]
pub struct TunnelHost {
    pub id: Uuid,
    pub name: Hostname,
    pub public_key: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Tunnel {
    pub id: Uuid,
    pub initiator: TunnelHost,
    pub responder: TunnelHost,
    pub cidr: IpNet,
    pub responder_port: u16,
    pub responder_ip: IpNet,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct GetTunnelsResponse {
    pub tunnels: Vec<Tunnel>,
}
