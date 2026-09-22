pub mod wireguard;

use std::net::{Ipv4Addr, Ipv6Addr, SocketAddr};

use anyhow::Context as _;
use ipnet::{IpNet, Ipv4Net, Ipv6Net};
use nix::ifaddrs::getifaddrs;
use rlib::hosts::HostAddress;

use crate::{config::Configuration, host::networking::wireguard::resolve_endpoint};

#[derive(Debug)]
pub struct WireguardInfo {
    key: wireguard::Key,
    endpoint: Option<SocketAddr>,
}

impl WireguardInfo {
    pub fn key(&self) -> &wireguard::Key {
        &self.key
    }

    pub fn endpoint(&self) -> Option<SocketAddr> {
        self.endpoint
    }
}

#[derive(Debug)]
pub struct HostNetworkInfo {
    addresses: Vec<HostAddress>,
    wireguard: Option<WireguardInfo>,
}

impl HostNetworkInfo {
    pub fn addresses(&self) -> impl Iterator<Item = &HostAddress> {
        self.addresses.iter()
    }

    pub fn wireguard(&self) -> Option<&WireguardInfo> {
        self.wireguard.as_ref()
    }
}

pub async fn read(config: &Configuration) -> anyhow::Result<HostNetworkInfo> {
    let all_addresses = getifaddrs().context("failed to get host addresses")?;
    let mut ip_addresses = vec![];

    for address in all_addresses {
        if let Some(ipv4) = address.address.and_then(|x| x.as_sockaddr_in().copied()) {
            let netmask = address
                .netmask
                .and_then(|x| x.as_sockaddr_in().cloned())
                .map(|y| y.ip())
                .unwrap_or(Ipv4Addr::new(255, 255, 255, 255));

            ip_addresses.push(HostAddress {
                address: IpNet::V4(Ipv4Net::with_netmask(ipv4.ip(), netmask)?),
                interface: address.interface_name.clone(),
            });
        } else if let Some(ipv6) = address.address.and_then(|x| x.as_sockaddr_in6().copied()) {
            let netmask = address
                .netmask
                .and_then(|x| x.as_sockaddr_in6().cloned())
                .map(|y| y.ip())
                .unwrap_or(Ipv6Addr::new(255, 255, 255, 255, 255, 255, 255, 255));

            ip_addresses.push(HostAddress {
                address: IpNet::V6(Ipv6Net::with_netmask(ipv6.ip(), netmask)?),
                interface: address.interface_name.clone(),
            })
        }
    }

    let wireguard = if let Some(wireguard) = config.wireguard.as_ref() {
        Some(WireguardInfo {
            key: wireguard::Key::load(wireguard)?,
            endpoint: resolve_endpoint(&wireguard.endpoint, ip_addresses.iter()).await?,
        })
    } else {
        None
    };

    Ok(HostNetworkInfo {
        addresses: ip_addresses,
        wireguard,
    })
}
