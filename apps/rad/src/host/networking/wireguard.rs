use std::{
    fs::{self, OpenOptions, Permissions},
    io::Write as _,
    net::{IpAddr, SocketAddr},
    os::unix::fs::{OpenOptionsExt, PermissionsExt},
};

use anyhow::Context;
use base64::Engine as _;
use ipnet::IpNet;
use rand::rng;
use rlib::{hosts::HostAddress, wireguard::WIREGUARD_PORT_DEFAULT};
use thiserror::Error;
use tokio::net::lookup_host;
use tracing::info;
use x25519_dalek::{PublicKey, StaticSecret};

use crate::{config, networking::is_global4};

#[derive(Debug)]
pub struct Key {
    public: PublicKey,
}

impl Key {
    pub fn load(config: &config::Wireguard) -> anyhow::Result<Key> {
        let private = match fs::read_to_string(&config.key_file) {
            Ok(contents) => {
                let bytes: [u8; 32] = base64::engine::general_purpose::STANDARD
                    .decode(contents)
                    .with_context(|| {
                        format!(
                            "failed to decode private wireguard key at {:?}",
                            config.key_file
                        )
                    })?
                    .try_into()
                    .unwrap();

                StaticSecret::from(bytes)
            }
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => {
                let secret = StaticSecret::random_from_rng(&mut rng());

                let mut key_file = OpenOptions::new()
                    .write(true)
                    .create(true)
                    .truncate(true)
                    .mode(0o600)
                    .open(&config.key_file)?;

                key_file
                    .write_all(
                        base64::engine::general_purpose::STANDARD
                            .encode(secret.as_bytes())
                            .as_bytes(),
                    )
                    .with_context(|| {
                        format!(
                            "failed to write a new wireguard key at {:?}",
                            config.key_file
                        )
                    })?;

                secret
            }
            Err(e) => {
                return Err(e).with_context(|| {
                    format!("failed to read wireguard key at {:?}", config.key_file)
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
