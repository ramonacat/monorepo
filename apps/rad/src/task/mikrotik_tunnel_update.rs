use std::{net::IpAddr, time::Duration};

use async_trait::async_trait;
use rlib::hosts::{HostAddress, NetworkingState, PostHostStateRequest, WireguardState};
use tracing::info;

use crate::{
    config::Configuration,
    host::identity::HostIdentity,
    mikrotik::Connection,
    ras_client::RasClient,
    task::{Task, TaskResult},
};

#[derive(Debug)]
pub struct MikrotikWireguardTunnelUpdate {}

impl MikrotikWireguardTunnelUpdate {
    pub fn new() -> Self {
        Self {}
    }
}

#[async_trait]
impl Task for MikrotikWireguardTunnelUpdate {
    async fn execute(
        &self,
        config: &Configuration,
        host_identity: &HostIdentity,
    ) -> anyhow::Result<TaskResult> {
        let state = config.state();

        let Some(config) = &config.mikrotik else {
            info!("no mikrotik config, not updating peers");
            return Ok(TaskResult::ScheduleAgainIn(Duration::from_mins(1)));
        };

        let ras_client = RasClient::new(host_identity.clone())?;
        let key = crate::host::networking::wireguard::Key::load(&config.wireguard.key_path)?;

        let connection = Connection::connect(
            config.endpoint,
            &config.username,
            config.password.read()?.as_ref().map(|x| x.as_str()),
        )
        .await?;
        let mut api = crate::mikrotik::api::Api::new(connection);

        let hostname = api.system_identity_get().await?.name;

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
                &hostname,
                &PostHostStateRequest {
                    closure: None,
                    networking: Some(NetworkingState {
                        addresses: ips,
                        wireguard: Some(WireguardState {
                            listen_addresses: vec![],
                            available_ports: vec![],
                            public_key: key.to_public_base64(),
                        }),
                    }),
                },
            )
            .await?;
        let tunnels = ras_client
            .get_wireguard_tunnels_for_host(&hostname)
            .await?
            .tunnels;

        for tunnel in tunnels {
            info!(?hostname, ?tunnel, "processing tunnel");

            let remote_endpoint = tunnel.remote_endpoint(&hostname);
            let local_endpoint = tunnel.local_endpoint(&hostname);

            let interface_name = remote_endpoint.hostname().to_string();

            let current_interface = api
                .interface_wireguard_find([format!("name={interface_name}").as_str()])
                .await?
                .pop();

            let responder_port = local_endpoint
                .as_responder()
                .and_then(|x| x.endpoint())
                .map(|x| x.port());

            if let Some(current_interface) = current_interface {
                if local_endpoint
                    .as_responder()
                    .and_then(|x| x.endpoint())
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
                    api.interface_wireguard_set(&current_interface.id, responder_port, &key)
                        .await?;
                }
            } else {
                api.interface_wireguard_add(&interface_name, responder_port, &key)
                    .await?;
            }

            let current_peer = api
                .interface_wireguard_peers_find([format!("interface={interface_name}").as_str()])
                .await?
                .pop();

            if let Some(current_peer) = current_peer {
                info!(?current_peer, "found existing peer");

                if remote_endpoint.public_key() != current_peer.public_key
                    || remote_endpoint
                        .as_responder()
                        .and_then(|x| x.endpoint())
                        .is_some_and(|x| {
                            x.ip() != current_peer.endpoint_address.parse::<IpAddr>().unwrap()
                        })
                {
                    api.interface_wireguard_peers_set(
                        &current_peer.id,
                        remote_endpoint.public_key(),
                        remote_endpoint.as_responder().and_then(|x| x.endpoint()),
                        "0.0.0.0/0,::/0",
                        "25s",
                    )
                    .await?;
                }
            } else {
                api.interface_wireguard_peers_add(
                    remote_endpoint.hostname().first_label(),
                    &interface_name,
                    remote_endpoint.public_key(),
                    remote_endpoint.as_responder().and_then(|x| x.endpoint()),
                    "0.0.0.0/0,::/0",
                    "25s",
                )
                .await?;
            }

            state
                .with_async(async |state| {
                    if let Some(id) = state.tunnel_ips.get(&tunnel.id()) {
                        api.ip_address_set(id, local_endpoint.tunnel_ip(), &interface_name)
                            .await?;
                    } else {
                        let id = api
                            .ip_address_add(local_endpoint.tunnel_ip(), &interface_name)
                            .await?;
                        state.tunnel_ips.insert(tunnel.id(), id);
                    }

                    Ok::<_, anyhow::Error>(())
                })
                .await?;
        }

        // TODO cleanup removed tunnels

        Ok(TaskResult::ScheduleAgainIn(Duration::from_mins(1)))
    }
}
