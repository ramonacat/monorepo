pub mod wireguard;

use std::net::{IpAddr, Ipv4Addr, Ipv6Addr, SocketAddr};

use anyhow::Context as _;
use ipnet::{IpNet, Ipv4Net, Ipv6Net};
use nix::ifaddrs::getifaddrs;
use rlib::hosts::HostAddress;
use tokio::net::lookup_host;
use tracing::info;

const WIREGUARD_PORT_DEFAULT: u16 = 51820;

#[derive(Debug)]
pub struct HostNetworkInfo {
    addresses: Vec<HostAddress>,
}

impl HostNetworkInfo {
    pub fn addresses(&self) -> impl Iterator<Item = &HostAddress> {
        self.addresses.iter()
    }

    pub async fn resolve_wireguard_endpoint(
        &self,
        endpoint: &crate::config::WireguardEndpoint,
    ) -> anyhow::Result<Option<SocketAddr>> {
        match endpoint {
            crate::config::WireguardEndpoint::Disabled => Ok(None),
            crate::config::WireguardEndpoint::Auto => {
                info!("finding a public address for wireguard");

                let public_ip = self
                    .addresses
                    .iter()
                    .filter_map(|x| {
                        if let IpNet::V4(v4) = x.address
                            && is_global4(&v4.addr())
                        {
                            Some(v4)
                        } else {
                            None
                        }
                    })
                    .next()
                    .expect("no public ipv4 found");

                Ok(Some(SocketAddr::new(
                    public_ip.addr().into(),
                    WIREGUARD_PORT_DEFAULT,
                )))
            }
            crate::config::WireguardEndpoint::Specified { host, port } => {
                let ip: Result<IpAddr, _> = host.parse();

                match ip {
                    Ok(ip) => return Ok(Some(SocketAddr::new(ip, *port))),
                    Err(e) => {
                        info!(?host, error=?e, "Failed to parse as ip, assuming it's a hostname");
                    }
                }

                let address = lookup_host(format!("{host}:{port}"))
                    .await?
                    .filter_map(|x| {
                        // TODO support ipv6 probably
                        if let SocketAddr::V4(v4) = x {
                            Some(v4)
                        } else {
                            None
                        }
                    })
                    .next();

                Ok(address.map(|x| x.into()))
            }
        }
    }
}

pub fn read() -> anyhow::Result<HostNetworkInfo> {
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

    Ok(HostNetworkInfo {
        addresses: ip_addresses,
    })
}

// this is basically a copy of Ipv4Addr::is_global from the standard library (it's unstable, but
// it is correct enough, so it's fine)
const fn is_global4(address: &Ipv4Addr) -> bool {
    !(address.octets()[0] == 0 // "This network"
        || address.is_private()
        || address.octets()[0] == 100 && (address.octets()[1] & 0b1100_0000 == 0b0100_0000)
        || address.is_loopback()
        || address.is_link_local()
        // addresses reserved for future protocols (`192.0.0.0/24`)
        // .9 and .10 are documented as globally reachable so they're excluded
        || (
            address.octets()[0] == 192 && address.octets()[1] == 0 && address.octets()[2] == 0
            && address.octets()[3] != 9 && address.octets()[3] != 10
        )
        || address.is_documentation()
        || address.octets()[0] == 198 && (address.octets()[1] & 0xfe) == 18
        || address.octets()[0] & 240 == 240 && !address.is_broadcast()
        || address.is_broadcast())
}
