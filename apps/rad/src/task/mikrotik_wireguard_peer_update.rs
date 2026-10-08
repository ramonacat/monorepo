use std::time::Duration;

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
pub struct MikrotikWireguardPeerUpdate {}

impl MikrotikWireguardPeerUpdate {
    pub fn new() -> Self {
        Self {}
    }
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
            let interface_name = if tunnel.initiator.name == hostname {
                tunnel.responder.name.first_label()
            } else {
                tunnel.initiator.name.first_label()
            };

            let current_interface = api
                .interface_wireguard_find([format!("name={interface_name}").as_str()])
                .await?
                .pop();

            if let Some(current_interface) = current_interface {
                if (tunnel.responder.name == hostname
                    && (current_interface.listen_port != tunnel.responder_port
                        || current_interface.public_key != tunnel.responder.public_key))
                    || (tunnel.initiator.name == hostname
                        && current_interface.public_key != tunnel.initiator.public_key)
                {
                    info!(
                        ?current_interface,
                        ?tunnel,
                        ?key,
                        "updating wireguard interface"
                    );
                    api.interface_wireguard_set(&current_interface.id, tunnel.responder_port, &key)
                        .await?;
                }
            } else {
                api.interface_wireguard_add(interface_name, tunnel.responder_port, &key)
                    .await?;
            }

            let current_peer = api
                .interface_wireguard_peers_find([format!("interface={interface_name}").as_str()])
                .await?
                .pop();

            let peer = if tunnel.initiator.name == hostname {
                &tunnel.responder
            } else {
                &tunnel.initiator
            };
            if let Some(current_peer) = current_peer {
                if peer.public_key != current_peer.public_key
                    || tunnel.responder_ip != current_peer.endpoint_address.parse().unwrap()
                {
                    api.interface_wireguard_peers_set(
                        &current_peer.id,
                        &peer.public_key,
                        tunnel.responder_ip.addr(),
                        tunnel.responder_port,
                        "0.0.0.0/0,::/0",
                        "25s",
                    )
                    .await?;
                }
            } else {
                api.interface_wireguard_peers_add(
                    interface_name,
                    &peer.public_key,
                    tunnel.responder_ip.addr(),
                    tunnel.responder_port,
                    "0.0.0.0/0,::/0",
                    "25s",
                )
                .await?;
            }
        }

        // TODO cleanup removed tunnels

        Ok(TaskResult::ScheduleAgainIn(Duration::from_mins(1)))
    }
}
