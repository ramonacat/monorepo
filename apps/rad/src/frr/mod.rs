use std::net::IpAddr;

use askama::Template;
use ipnet::IpNet;

#[derive(Debug)]
pub struct Interface {
    name: String,
    cost: u32,
    is_tunnel: bool,
}

impl Interface {
    pub fn new(name: String, cost: u32, is_tunnel: bool) -> Self {
        Self {
            name,
            cost,
            is_tunnel,
        }
    }
}

#[derive(Debug, Template)]
#[template(path = "frr.conf")]
pub struct ConfigTemplate {
    router_id: IpAddr,
    denied_cidrs: Vec<IpNet>,
    interfaces: Vec<Interface>,
}

impl ConfigTemplate {
    pub fn new(router_id: IpAddr, denied_cidrs: Vec<IpNet>, interfaces: Vec<Interface>) -> Self {
        Self {
            router_id,
            denied_cidrs,
            interfaces,
        }
    }
}
