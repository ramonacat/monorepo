use std::net::IpAddr;

use askama::Template;

#[derive(Debug)]
pub struct Interface {
    name_pattern: String,
    cost: u32,
    is_tunnel: bool,
}

impl Interface {
    pub fn new(name_pattern: String, cost: u32, is_tunnel: bool) -> Self {
        Self {
            name_pattern,
            cost,
            is_tunnel,
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
}

impl ConfigTemplate {
    pub fn new(
        router_id: IpAddr,
        filter_import: String,
        filter_export: String,
        interfaces: Vec<Interface>,
        additional_config: String,
    ) -> Self {
        Self {
            router_id,
            filter_import,
            filter_export,
            interfaces,
            additional_config,
        }
    }
}
