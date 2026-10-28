use std::net::IpAddr;

use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Deserialize, Serialize, PartialEq, Eq, Clone)]
pub enum ServiceProtocol {
    Tcp,
    Udp,
}

#[derive(Debug, Deserialize, Serialize, PartialEq, Eq, Clone)]
pub struct ServicePort {
    pub protocol: ServiceProtocol,
    pub exposed_port: u16,
    pub host_port: u16,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct PostUpsertRequest {
    pub host_group_id: Uuid,
    pub ports: Vec<ServicePort>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct PostUpsertResponse {
    pub ip_address: IpAddr,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct LoadBalancer {
    pub ip: IpAddr,
    pub ports: Vec<ServicePort>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct GetByHostResponse {
    pub balancers: Vec<LoadBalancer>,
}
