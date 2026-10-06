use std::net::{IpAddr, SocketAddr};

use ipnet::IpNet;
use rlib::{hosts::HostAddress, wireguard::WIREGUARD_PORT_DEFAULT};
use thiserror::Error;
use tokio::net::lookup_host;
use tracing::info;

use crate::networking::is_global4;

#[derive(Debug, Error)]
pub enum ResolveEndpointError {
    #[error("failed to resolve host {0} with port {1}")]
    CannotResolveHost(String, u16),
}

pub async fn resolve_endpoint(
    endpoint: &crate::config::WireguardEndpoint,
    addresses: impl Iterator<Item = HostAddress>,
) -> anyhow::Result<Option<SocketAddr>> {
    match endpoint {
        crate::config::WireguardEndpoint::InitiatorOnly => Ok(None),
        crate::config::WireguardEndpoint::Auto => {
            info!("finding a public address for wireguard");

            let public_ip = addresses
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

            Ok(Some(
                address
                    .ok_or_else(|| ResolveEndpointError::CannotResolveHost(host.clone(), *port))?
                    .into(),
            ))
        }
    }
}
