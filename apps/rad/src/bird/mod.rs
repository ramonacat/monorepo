use std::net::IpAddr;

use askama::Template;
use ipnet::IpNet;

use crate::config::RoutingInterfaceKind;

#[derive(Debug)]
pub struct Interface {
    name_pattern: String,
    cost: u32,
    kind: RoutingInterfaceKind,
}

impl Interface {
    pub const fn new(name_pattern: String, cost: u32, kind: RoutingInterfaceKind) -> Self {
        Self {
            name_pattern,
            cost,
            kind,
        }
    }
}

#[derive(Debug)]
pub struct Route {
    pub via: IpAddr,
    pub target_cidr: IpNet,
    pub blackhole: bool,
}

impl Route {
    pub const fn new(via: IpAddr, target_cidr: IpNet, blackhole: bool) -> Self {
        Self {
            via,
            target_cidr,
            blackhole,
        }
    }
}

#[derive(Debug, Template)]
#[template(path = "bird.conf")]
pub struct ConfigTemplate {
    router_id: IpAddr,
    filter_import: String,
    filter_export: String,
    interfaces: Vec<Interface>,
    additional_config: String,
    static_routes: Vec<Route>,
}

impl ConfigTemplate {
    pub const fn new(
        router_id: IpAddr,
        filter_import: String,
        filter_export: String,
        interfaces: Vec<Interface>,
        additional_config: String,
        static_routes: Vec<Route>,
    ) -> Self {
        Self {
            router_id,
            filter_import,
            filter_export,
            interfaces,
            additional_config,
            static_routes,
        }
    }
}
