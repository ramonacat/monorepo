use std::net::IpAddr;

use ipnet::IpNet;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::hosts::Hostname;

#[derive(Debug, Serialize, Deserialize)]
pub struct Route {
    pub id: Uuid,
    pub target_hostname: Hostname,
    pub target_ips: Vec<IpAddr>,
    pub target_cidr: IpNet,
    pub blackhole: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct GetRoutesResponse {
    pub routes: Vec<Route>,
}
