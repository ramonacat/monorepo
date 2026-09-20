mod config;

use std::{
    env, fs,
    net::{IpAddr, Ipv4Addr, Ipv6Addr, SocketAddr},
    path::PathBuf,
    time::Duration,
};

use base64::Engine;
use ipnet::{IpNet, Ipv4Net, Ipv6Net};
use nix::ifaddrs::getifaddrs;
use rand::rng;
use reqwest::Identity;
use rlib::hosts::{ClosureUpdate, ConnectivityState, PostHostStateRequest, UDPEndpoint};
use thiserror::Error;
use tokio::{net::lookup_host, time::sleep};
use tracing::{info, warn};
use x25519_dalek::{PublicKey, StaticSecret};

#[tokio::main]
async fn main() {
    dotenvy::dotenv().ok();
    tracing_subscriber::fmt().init();

    loop {
        let config_path: PathBuf = env::var("RAMONA_CONFIG_PATH").unwrap().parse().unwrap();
        let config: config::Configuration =
            serde_json::from_str(&fs::read_to_string(config_path).unwrap()).unwrap();

        let mut pem_bundle = fs::read(config.key).unwrap();
        pem_bundle.push(b'\n');
        pem_bundle.extend_from_slice(&fs::read(config.certificate).unwrap());

        let identity = Identity::from_pem(&pem_bundle).unwrap();
        let client = reqwest::Client::builder()
            .identity(identity)
            .build()
            .unwrap();

        let current_closure = fs::canonicalize("/nix/var/nix/profiles/system").unwrap();
        let ip_addresses = getifaddrs().unwrap();

        let addresses: Vec<IpNet> = ip_addresses
            .filter_map(|x| {
                let address = x.address?;

                if let Some(ipv4) = address.as_sockaddr_in() {
                    let netmask = x
                        .netmask
                        .and_then(|x| x.as_sockaddr_in().cloned())
                        .map(|y| y.ip())
                        .unwrap_or(Ipv4Addr::new(255, 255, 255, 255));

                    Some(IpNet::V4(
                        Ipv4Net::with_netmask(ipv4.ip(), netmask).unwrap(),
                    ))
                } else if let Some(ipv6) = address.as_sockaddr_in6() {
                    let netmask = x
                        .netmask
                        .and_then(|x| x.as_sockaddr_in6().cloned())
                        .map(|y| y.ip())
                        .unwrap_or(Ipv6Addr::new(255, 255, 255, 255, 255, 255, 255, 255));

                    Some(IpNet::V6(
                        Ipv6Net::with_netmask(ipv6.ip(), netmask).unwrap(),
                    ))
                } else {
                    None
                }
            })
            .collect();

        let endpoint = resolve_wireguard_endpoint(&config.wireguard, &addresses)
            .await
            .unwrap();

        let request_body = PostHostStateRequest {
            connectivity: ConnectivityState {
                addresses,
                wireguard: endpoint.map(|x| rlib::hosts::WireguardEndpoint {
                    public_key: ensure_public_key(),
                    endpoint: Some(x),
                }),
            },
            closure: Some(ClosureUpdate {
                latest_closure: None,
                current_closure: Some(current_closure.to_string_lossy().into()),
            }),
        };

        let hostname = nix::unistd::gethostname().unwrap();
        let response = client
            .post(format!(
                "https://ras.ramona.fun:1443/hosts/{}",
                hostname.to_string_lossy()
            ))
            .json(&request_body)
            .send()
            .await
            .unwrap();

        if response.status().is_success() {
            info!(?response, "host state updated");
        } else {
            warn!(?response, "failed to update host state");
        }

        sleep(Duration::from_secs(60)).await;
    }
}

#[derive(Debug, Error)]
enum ResolveWireguardEndpointError {
    #[error("io: {0}")]
    Io(#[from] std::io::Error),
}

const WIREGUARD_PORT_DEFAULT: u16 = 51820;

async fn resolve_wireguard_endpoint(
    endpoint: &config::WireguardEndpoint,
    addresses: &[IpNet],
) -> Result<Option<UDPEndpoint>, ResolveWireguardEndpointError> {
    Ok(match endpoint {
        config::WireguardEndpoint::Disabled => None,
        config::WireguardEndpoint::Auto => {
            info!(?addresses, "finding a public address for wireguard");
            let public_ip = addresses
                .iter()
                .filter_map(|x| {
                    if let IpNet::V4(v4) = x {
                        Some(v4)
                    } else {
                        None
                    }
                })
                .find(|x| is_global4(&x.addr()))
                .expect("no public ipv4 found");

            Some(UDPEndpoint::new(
                (*public_ip).into(),
                WIREGUARD_PORT_DEFAULT,
            ))
        }
        config::WireguardEndpoint::Specified { host, port } => {
            let ip: Result<IpAddr, _> = host.parse();

            match ip {
                Ok(ip) => Some(UDPEndpoint::new(ip.into(), *port)),
                Err(e) => {
                    info!(?host, error=?e, "Failed to parse as ip, assuming it's a hostname");

                    lookup_host(format!("{host}:{port}"))
                        .await?
                        .filter_map(|x| {
                            if let SocketAddr::V4(v4) = x {
                                Some(v4)
                            } else {
                                None
                            }
                        })
                        .next()
                        .map(|x| UDPEndpoint::new(IpNet::V4((*x.ip()).into()), x.port()))
                }
            }
        }
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

const WIREGUARD_KEY_PATH: &str = "/var/ramona/wireguard.key";

fn ensure_public_key() -> String {
    let secret = match fs::read_to_string(WIREGUARD_KEY_PATH) {
        Ok(contents) => {
            let bytes: [u8; 32] = base64::engine::general_purpose::STANDARD
                .decode(contents)
                .unwrap()
                .try_into()
                .unwrap();

            StaticSecret::from(bytes)
        }
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => {
            let secret = StaticSecret::random_from_rng(&mut rng());

            fs::write(
                WIREGUARD_KEY_PATH,
                base64::engine::general_purpose::STANDARD.encode(secret.as_bytes()),
            )
            .unwrap();

            secret
        }
        Err(e) => {
            panic!("failed to read wireguard key: {e}");
        }
    };

    base64::engine::general_purpose::STANDARD.encode(PublicKey::from(&secret).to_bytes())
}
