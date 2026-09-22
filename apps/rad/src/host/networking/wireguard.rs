use std::{
    fs,
    net::{IpAddr, Ipv4Addr, SocketAddr},
};

use anyhow::Context;
use base64::Engine as _;
use ipnet::IpNet;
use rand::rng;
use rlib::hosts::HostAddress;
use thiserror::Error;
use tokio::net::lookup_host;
use tracing::info;
use x25519_dalek::{PublicKey, StaticSecret};

use crate::config;

const WIREGUARD_PORT_DEFAULT: u16 = 51820;

#[derive(Debug)]
pub struct Key {
    public: PublicKey,
}

impl Key {
    pub fn load(config: &config::Wireguard) -> anyhow::Result<Key> {
        let private = match fs::read_to_string(&config.key_path) {
            Ok(contents) => {
                let bytes: [u8; 32] = base64::engine::general_purpose::STANDARD
                    .decode(contents)
                    .with_context(|| {
                        format!(
                            "failed to decode private wireguard key at {:?}",
                            config.key_path
                        )
                    })?
                    .try_into()
                    .unwrap();

                StaticSecret::from(bytes)
            }
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => {
                let secret = StaticSecret::random_from_rng(&mut rng());

                fs::write(
                    &config.key_path,
                    base64::engine::general_purpose::STANDARD.encode(secret.as_bytes()),
                )
                .with_context(|| {
                    format!(
                        "failed to write a new wireguard key at {:?}",
                        config.key_path
                    )
                })?;

                secret
            }
            Err(e) => {
                return Err(e).with_context(|| {
                    format!("failed to read wireguard key at {:?}", config.key_path)
                });
            }
        };

        let public = PublicKey::from(&private);

        Ok(Self { public })
    }

    pub fn to_public_base64(&self) -> String {
        base64::engine::general_purpose::STANDARD.encode(self.public.as_bytes())
    }
}

#[derive(Debug, Error)]
pub enum ResolveEndpointError {
    #[error("failed to resolve host {0} with port {1}")]
    CannotResolveHost(String, u16),
}

pub(super) async fn resolve_endpoint(
    endpoint: &crate::config::WireguardEndpoint,
    addresses: impl Iterator<Item = &HostAddress>,
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
