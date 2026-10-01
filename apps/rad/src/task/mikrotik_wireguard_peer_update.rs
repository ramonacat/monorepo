use std::{
    collections::HashMap,
    net::{IpAddr, SocketAddr},
    str::FromStr,
    time::Duration,
};

use async_trait::async_trait;
use ipnet::IpNet;
use rlib::{
    hosts::{ConnectivityState, HostAddress, PostHostStateRequest},
    wireguard::WireguardEndpoint,
};
use thiserror::Error;
use tokio::net::lookup_host;
use tracing::info;

use crate::{
    config::Configuration,
    host::identity::HostIdentity,
    mikrotik::{Connection, ResponseLine},
    networking::is_global4,
    ras_client::RasClient,
    task::{Task, TaskResult},
};

#[derive(Debug)]
pub struct MikrotikWireguardPeerUpdate {}

impl MikrotikWireguardPeerUpdate {}

impl MikrotikWireguardPeerUpdate {
    pub fn new() -> Self {
        Self {}
    }
}

fn endpoint_to_attributes(
    interface: String,
    hostname: String,
    endpoint: &WireguardEndpoint,
) -> HashMap<String, String> {
    let mut attributes: HashMap<String, String> = [
        ("name".to_string(), hostname),
        ("interface".to_string(), interface),
        ("allowed-address".to_string(), "0.0.0.0/0,::/0".to_string()),
        ("public-key".to_string(), endpoint.public_key.clone()),
        // TODO: make this configurable
        ("persistent-keepalive".to_string(), "50s".to_string()),
    ]
    .into();

    if let Some(address) = endpoint.endpoint {
        let ip = address.ip().to_string();
        let port = address.port().to_string();

        attributes.insert("endpoint-address".to_string(), ip);
        attributes.insert("endpoint-port".to_string(), port);
    } else {
        attributes.insert("responder".to_string(), "true".to_string());
    }

    attributes
}

#[derive(Debug, Error)]
pub enum PeerUpdateError {
    #[error("name not known for: {0:?}")]
    NameNotKnown(HashMap<String, String>),
    #[error("the device does not have a public ip")]
    NoPublicIp,
}

#[async_trait]
impl Task for MikrotikWireguardPeerUpdate {
    async fn execute(
        &self,
        config: &Configuration,
        host_identity: &HostIdentity,
    ) -> anyhow::Result<TaskResult> {
        let Some(config) = &config.mikrotik else {
            info!("no mikrotik config, not updating peers");
            return Ok(TaskResult::ScheduleAgainIn(Duration::from_mins(1)));
        };

        // TODO actually get the endpoints from ras, compare with what the router knows and update
        // as necessary
        let ras_client = RasClient::new(host_identity.clone())?;
        let mut endpoints = ras_client.get_wireguard_endpoints().await?.endpoints;

        let mut connection = Connection::connect(
            config.endpoint,
            &config.username,
            config.password.read()?.as_ref().map(|x| x.as_str()),
        )
        .await?;
        let interface = &config.wireguard.interface;

        let hostname = connection
            .send("system/identity/print", [], [])
            .await?
            .into_iter()
            .filter_map(|x| match x {
                ResponseLine::Done | ResponseLine::Empty => None,
                ResponseLine::Data(hash_map) => Some(
                    hash_map
                        .get("name")
                        .unwrap()
                        .split(".")
                        .nth(0)
                        .unwrap()
                        .to_string(),
                ),
            })
            .nth(0)
            .unwrap();
        endpoints.remove(&hostname);
        let wireguard_interaface_description = connection
            .send(
                "interface/wireguard/print",
                [],
                [format!("name={interface}").as_str()],
            )
            .await?
            .into_iter()
            .filter_map(|x| match x {
                ResponseLine::Empty | ResponseLine::Done => None,
                ResponseLine::Data(hash_map) => Some((
                    u16::from_str(hash_map.get("listen-port").unwrap().as_str()).unwrap(),
                    hash_map.get("public-key").unwrap().to_string(),
                )),
            })
            .nth(0)
            .unwrap();
        // TODO support IPv6
        let ip_addresses = connection.send("ip/address/print", [], []).await?;
        let ips = ip_addresses.iter().filter_map(|x| {
            if let ResponseLine::Data(data) = x {
                dbg!(data);
                Some(HostAddress {
                    address: <IpNet as FromStr>::from_str(data.get("address").unwrap())
                        .unwrap()
                        .addr()
                        .into(),
                    interface: data.get("interface").unwrap().to_string(),
                })
            } else {
                None
            }
        });

        // TODO this is very similar to the way it's done in the host update task, probably abstract
        // it out, so it's not copy-pasted?
        let wireguard_endpoint = match &config.wireguard.endpoint {
            crate::config::WireguardEndpoint::InitiatorOnly => None,
            crate::config::WireguardEndpoint::Auto => {
                let ip = ips
                    .clone()
                    .filter_map(|x| {
                        if let IpAddr::V4(v4) = x.address.addr()
                            && is_global4(&v4)
                        {
                            Some(x)
                        } else {
                            None
                        }
                    })
                    .nth(0)
                    .ok_or(PeerUpdateError::NoPublicIp)?;

                Some(SocketAddr::new(
                    ip.address.addr(),
                    wireguard_interaface_description.0,
                ))
            }
            crate::config::WireguardEndpoint::Specified { host, port } => {
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
                    .next()
                    .unwrap();

                Some(address.into())
            }
        };

        ras_client
            .update_host_state(
                &hostname,
                &PostHostStateRequest {
                    connectivity: ConnectivityState {
                        addresses: ips.collect(),
                        wireguard: Some(rlib::wireguard::WireguardEndpoint {
                            public_key: wireguard_interaface_description.1,
                            endpoint: wireguard_endpoint,
                        }),
                    },
                    closure: None,
                },
            )
            .await?;

        let peers = connection
            .send(
                "interface/wireguard/peers/print",
                [],
                [format!("interface={interface}").as_str()],
            )
            .await?;
        info!(current=?peers, new=?endpoints, "updating wireguard endpoints");

        for peer in peers {
            match peer {
                ResponseLine::Done | ResponseLine::Empty => {}
                ResponseLine::Data(attributes) => {
                    let Some(hostname) = attributes.get("name") else {
                        return Err(PeerUpdateError::NameNotKnown(attributes).into());
                    };

                    if let Some(current_definition) = endpoints.remove(hostname) {
                        let expected_attributes = endpoint_to_attributes(
                            interface.to_string(),
                            hostname.to_string(),
                            &current_definition,
                        );

                        let mut needs_update = false;
                        for (name, value) in &expected_attributes {
                            let actual_value = attributes.get(name);
                            if actual_value != Some(value) {
                                info!(
                                    ?hostname,
                                    ?name,
                                    ?value,
                                    ?actual_value,
                                    "mismatched attirbute"
                                );
                                needs_update = true;
                                break;
                            }
                        }

                        if needs_update {
                            info!(new=?expected_attributes, old=?attributes, "updating peer");
                            connection
                                .send(
                                    "interface/wireguard/peers/set",
                                    expected_attributes
                                        .iter()
                                        .map(|(k, v)| (k.as_str(), v.as_str()))
                                        .chain([(".id", attributes.get(".id").unwrap().as_str())]),
                                    [],
                                )
                                .await?;
                        }
                    } else {
                        info!(?attributes, "removing peer");

                        connection
                            .send(
                                "interface/wireguard/peers/remove",
                                [(".id", attributes.get(".id").unwrap().as_str())],
                                [],
                            )
                            .await?;
                    }
                }
            }
        }

        for (hostname, endpoint) in endpoints {
            let attributes = endpoint_to_attributes(interface.to_string(), hostname, &endpoint);
            info!(?attributes, "adding peer");

            connection
                .send(
                    "interface/wireguard/peers/add",
                    attributes.iter().map(|(k, v)| (k.as_str(), v.as_str())),
                    [],
                )
                .await?;
        }

        Ok(TaskResult::ScheduleAgainIn(Duration::from_mins(1)))
    }
}
