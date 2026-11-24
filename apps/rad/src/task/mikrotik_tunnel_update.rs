use std::{collections::HashMap, net::IpAddr, time::Duration};

use async_trait::async_trait;
use rlib::{
    hosts::{HostAddress, Hostname, NetworkingState, PostHostStateRequest, WireguardState},
    wireguard::{RemoteEndpoint, Tunnel},
};
use tracing::{debug, info};

use crate::{
    mikrotik::Connection,
    state::{StateManager, TunnelState},
    task::{Task, TaskContext, TaskResult},
};

#[derive(Debug)]
pub struct MikrotikWireguardTunnelUpdate {}

impl MikrotikWireguardTunnelUpdate {
    pub const fn new() -> Self {
        Self {}
    }
}

#[async_trait]
impl Task for MikrotikWireguardTunnelUpdate {
    async fn execute(&self, context: TaskContext<'_>) -> anyhow::Result<TaskResult> {
        let state = context.config.state();

        let Some(config) = &context.config.mikrotik else {
            info!("no mikrotik config, not updating peers");
            return Ok(TaskResult::ScheduleAgainIn(Duration::from_mins(1)));
        };

        let ras_client = context.make_ras_client()?;
        let key = crate::host::networking::wireguard::Key::load(&config.wireguard.key_path)?;

        let connection = Connection::connect(
            config.endpoint,
            &config.username,
            config
                .password
                .read()?
                .as_ref()
                .map(std::string::String::as_str),
        )
        .await?;
        let mut api = crate::mikrotik::api::Api::new(connection);

        let hostname = api.system_identity_get().await?.name;

        update_state(&ras_client, &key, &mut api, &hostname).await?;

        let tunnels = ras_client
            .get_wireguard_tunnels_for_host(&hostname)
            .await?
            .tunnels;

        migrate_state(&state, &tunnels, &hostname).await?;

        for tunnel in &tunnels {
            info!(?hostname, ?tunnel, "processing tunnel");

            let remote_endpoint = tunnel.remote_endpoint(&hostname);
            let local_endpoint = tunnel.local_endpoint(&hostname);

            let interface_name = remote_endpoint.hostname().to_string();

            reconcile_interface(&key, &mut api, tunnel, &local_endpoint, &interface_name).await?;
            reoncile_peer(&mut api, &interface_name, &remote_endpoint).await?;

            state
                .with_async(async |state| {
                    if let Some(id) = state.tunnel_ips2.get(&tunnel.id()) {
                        let current_ips = api
                            .ip_address_find([format!(".id={}", id.mikrotik_ip_id).as_str()])
                            .await?;
                        let current_ip = current_ips.first();

                        if current_ip.is_none_or(|x| {
                            x.address != local_endpoint.tunnel_ip() || x.interface != interface_name
                        }) {
                            api.ip_address_set(
                                &id.mikrotik_ip_id,
                                local_endpoint.tunnel_ip(),
                                &interface_name,
                            )
                            .await?;
                        } else {
                            debug!(?tunnel, "no need to update ip");
                        }
                    } else {
                        let id = api
                            .ip_address_add(local_endpoint.tunnel_ip(), &interface_name)
                            .await?;
                        state.tunnel_ips2.insert(
                            tunnel.id(),
                            TunnelState {
                                mikrotik_ip_id: id,
                                name: interface_name,
                            },
                        );
                    }

                    Ok::<_, anyhow::Error>(())
                })
                .await?;
        }

        cleanup_deleted_tunnels(&state, &tunnels, &mut api).await?;

        Ok(TaskResult::ScheduleAgainIn(Duration::from_mins(1)))
    }
}

async fn reconcile_interface(
    key: &crate::host::networking::wireguard::Key,
    api: &mut crate::mikrotik::api::Api<tokio_rustls::client::TlsStream<tokio::net::TcpStream>>,
    tunnel: &rlib::wireguard::Tunnel,
    local_endpoint: &rlib::wireguard::LocalEndpoint<'_>,
    interface_name: &String,
) -> Result<(), anyhow::Error> {
    let current_interface = api
        .interface_wireguard_find([format!("name={interface_name}").as_str()])
        .await?
        .pop();
    let responder_port = local_endpoint
        .as_responder()
        .and_then(rlib::wireguard::Responder::endpoint)
        .map(|x| x.port());
    if let Some(current_interface) = current_interface {
        if local_endpoint
            .as_responder()
            .and_then(rlib::wireguard::Responder::endpoint)
            .map(|x| x.port())
            != current_interface.listen_port
            || local_endpoint.public_key() != current_interface.public_key
        {
            info!(
                ?current_interface,
                ?tunnel,
                ?key,
                "updating wireguard interface"
            );
            api.interface_wireguard_set(&current_interface.id, responder_port, key)
                .await?;
        }
    } else {
        api.interface_wireguard_add(interface_name, responder_port, key)
            .await?;
    }

    Ok(())
}

async fn reoncile_peer(
    api: &mut crate::mikrotik::api::Api<tokio_rustls::client::TlsStream<tokio::net::TcpStream>>,
    interface_name: &str,
    remote_endpoint: &RemoteEndpoint<'_>,
) -> anyhow::Result<()> {
    let current_peer = api
        .interface_wireguard_peers_find([format!("interface={interface_name}").as_str()])
        .await?
        .pop();

    if let Some(current_peer) = current_peer {
        info!(?current_peer, "found existing peer");

        if remote_endpoint.public_key() != current_peer.public_key
            || remote_endpoint
                .as_responder()
                .and_then(rlib::wireguard::Responder::endpoint)
                .is_some_and(|x| x.ip() != current_peer.endpoint_address.parse::<IpAddr>().unwrap())
            || current_peer.name != interface_name
        {
            api.interface_wireguard_peers_set(
                &current_peer.id,
                interface_name,
                remote_endpoint.public_key(),
                remote_endpoint
                    .as_responder()
                    .and_then(rlib::wireguard::Responder::endpoint),
                "0.0.0.0/0,::/0",
                "25s",
            )
            .await?;
        }
    } else {
        api.interface_wireguard_peers_add(
            remote_endpoint.hostname().first_label(),
            interface_name,
            remote_endpoint.public_key(),
            remote_endpoint
                .as_responder()
                .and_then(rlib::wireguard::Responder::endpoint),
            "0.0.0.0/0,::/0",
            "25s",
        )
        .await?;
    }
    Ok(())
}

async fn update_state(
    ras_client: &rlib::ras_client::RasClient,
    key: &crate::host::networking::wireguard::Key,
    api: &mut crate::mikrotik::api::Api<tokio_rustls::client::TlsStream<tokio::net::TcpStream>>,
    hostname: &rlib::hosts::Hostname,
) -> Result<(), anyhow::Error> {
    let ips: Vec<_> = api
        .ip_address_find([])
        .await?
        .into_iter()
        .map(|x| HostAddress {
            address: x.address,
            interface: x.interface,
        })
        .collect();
    ras_client
        .update_host_state(
            hostname,
            &PostHostStateRequest {
                closure: None,
                networking: Some(NetworkingState {
                    addresses: ips,
                    wireguard: Some(WireguardState {
                        listen_addresses: vec![],
                        available_ports: vec![],
                        public_key: key.to_public_base64(),
                    }),
                    main_ip: None,
                }),
                group_names: vec![],
            },
        )
        .await?;
    Ok(())
}

async fn migrate_state(
    state: &StateManager,
    tunnels: &[Tunnel],
    hostname: &Hostname,
) -> anyhow::Result<()> {
    state
        .with_async(async |state| {
            if state.tunnel_ips2.is_empty() && !state.tunnel_ips.is_empty() {
                for (id, mikrotik_id) in &state.tunnel_ips {
                    let tunnel = tunnels.iter().find(|x| x.id() == *id);

                    state.tunnel_ips2.insert(
                        *id,
                        TunnelState {
                            mikrotik_ip_id: mikrotik_id.clone(),
                            name: tunnel.map_or_else(
                                || "<unknown>".to_string(),
                                |x| {
                                    x.remote_endpoint(hostname)
                                        .hostname()
                                        .first_label()
                                        .to_string()
                                },
                            ),
                        },
                    );
                }

                state.tunnel_ips = HashMap::new();
            }

            anyhow::Ok(())
        })
        .await?;

    Ok(())
}

async fn cleanup_deleted_tunnels(
    state: &StateManager,
    tunnels: &[Tunnel],
    api: &mut crate::mikrotik::api::Api<tokio_rustls::client::TlsStream<tokio::net::TcpStream>>,
) -> anyhow::Result<()> {
    state
        .with_async(async |state| {
            for (id, tunnel) in &state.tunnel_ips2 {
                if tunnels.iter().any(|x| x.id() == *id) {
                    continue;
                }

                let interface_name = &tunnel.name;

                api.ip_address_remove([format!(".id={}", tunnel.mikrotik_ip_id).as_str()])
                    .await?;
                api.interface_wireguard_peers_remove([
                    format!("interface={interface_name}").as_str()
                ])
                .await?;
                api.interface_wireguard_remove([format!("name={interface_name}").as_str()])
                    .await?;
            }

            anyhow::Ok(())
        })
        .await?;
    Ok(())
}
