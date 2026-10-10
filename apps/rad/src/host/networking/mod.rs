pub mod wireguard;

use std::net::{Ipv4Addr, Ipv6Addr};

use anyhow::Context as _;
use ipnet::{IpNet, Ipv4Net, Ipv6Net};
use nix::ifaddrs::getifaddrs;
use rlib::{hosts::HostAddress, networking::is_global4};
use tokio::net::lookup_host;

use crate::config::Configuration;

const DEFAULT_WIREGUARD_PORTS: [u16; 10] = [
    51820, 51821, 51822, 51823, 51824, 51825, 51826, 51827, 51828, 51829,
];

#[derive(Debug)]
pub struct WireguardInfo {
    key: wireguard::Key,
    addresses: Vec<IpNet>,
    available_ports: Vec<u16>,
}

impl WireguardInfo {
    pub fn key(&self) -> &wireguard::Key {
        &self.key
    }

    pub fn addresses(&self) -> &[IpNet] {
        &self.addresses
    }

    pub fn available_ports(&self) -> &[u16] {
        &self.available_ports
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
        let (addresses, ports) = match &wireguard.endpoint {
            crate::config::WireguardEndpoint::InitiatorOnly => (vec![], vec![]),
            crate::config::WireguardEndpoint::Auto { available_ports } => {
                (
                    ip_addresses
                        .iter()
                        .filter_map(|x| match x.address {
                            IpNet::V4(ipv4_net) => {
                                if is_global4(&ipv4_net.addr()) {
                                    Some(ipv4_net.into())
                                } else {
                                    None
                                }
                            }
                            // TODO support IPv6
                            IpNet::V6(_) => None,
                        })
                        .collect(),
                    available_ports
                        .clone()
                        .unwrap_or(DEFAULT_WIREGUARD_PORTS.to_vec()),
                )
            }
            crate::config::WireguardEndpoint::Specified {
                host,
                available_ports,
            } => (
                lookup_host(format!("{host}:80"))
                    .await?
                    .map(|x| x.ip().into())
                    .collect(),
                available_ports
                    .clone()
                    .unwrap_or_else(|| DEFAULT_WIREGUARD_PORTS.to_vec()),
            ),
        };

        Some(WireguardInfo {
            key: wireguard::Key::load(&wireguard.key_file)?,
            addresses,
            available_ports: ports,
        })
    } else {
        None
    };

    Ok(HostNetworkInfo {
        addresses: ip_addresses,
        wireguard,
    })
}
