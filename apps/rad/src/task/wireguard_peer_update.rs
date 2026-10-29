use crate::linux::make_interface_name;
use crate::systemd::NetworkUnits;
use crate::task::TaskContext;
use std::{collections::HashMap, fs, path::PathBuf, time::Duration};

use async_trait::async_trait;
use tracing::debug;

use crate::task::{Task, TaskResult};

#[derive(Debug)]
pub struct WireguardPeerUpdate {}

impl WireguardPeerUpdate {
    pub fn new() -> Self {
        Self {}
    }
}

#[async_trait]
impl Task for WireguardPeerUpdate {
    async fn execute(&self, context: TaskContext<'_>) -> anyhow::Result<TaskResult> {
        let Some(wireguard_config) = &context.config.wireguard else {
            debug!("wireguard not enabled");

            return Ok(TaskResult::ScheduleAgainIn(Duration::from_mins(1)));
        };
        let ras_client = context.make_ras_client()?;
        let tunnels = ras_client
            .get_wireguard_tunnels_for_host(context.host_identity.hostname())
            .await?
            .tunnels;

        let network_units = NetworkUnits::new();

        let units: HashMap<String, String> = tunnels
            .into_iter()
            .flat_map(|tunnel| {
                // TODO let (remote, local) = tunnel.endpoints() maybe
                let remote_endpoint = tunnel.remote_endpoint(context.host_identity.hostname());
                let local_endpoint = tunnel.local_endpoint(context.host_identity.hostname());

                let peer_id_str = remote_endpoint.host_id().simple().to_string();
                let interface_name = make_interface_name("wg-", &peer_id_str);

                let netdev = (
                    format!("{}.netdev", remote_endpoint.hostname().first_label()),
                    format!(
                        "
[NetDev]
# {peer_name:?}
Name={interface_name}
Kind=wireguard
[WireGuard]
PrivateKeyFile={private_key_file}
{listen_port}
[WireGuardPeer]
PublicKey={peer_public_key}
AllowedIPs=0.0.0.0/0,::/0
{endpoint}
PersistentKeepalive=25
                    ",
                        peer_name = remote_endpoint.hostname(),
                        private_key_file = wireguard_config.key_file.to_string_lossy(),
                        listen_port = local_endpoint
                            .as_responder()
                            .and_then(|x| x.endpoint())
                            .map_or_else(String::new, |x| format!("ListenPort={}", x.port())),
                        peer_public_key = remote_endpoint.public_key(),
                        endpoint = remote_endpoint
                            .as_responder()
                            .and_then(|x| x.endpoint())
                            .map_or_else(String::new, |x| format!(
                                "Endpoint={}:{}",
                                x.ip(),
                                x.port()
                            )),
                    ),
                );

                let network = (
                    format!("{}.network", remote_endpoint.hostname().first_label()),
                    format!(
                        "
[Match]
Name={interface_name}
[Link]
ActivationPolicy=always-up
[Network]
Address={address}
                        ",
                        address = local_endpoint.tunnel_ip(),
                    ),
                );

                [netdev, network]
            })
            .collect();

        // TODO this deletes files from the previous version of this mechanism, delete after deployment
        for name in units.keys() {
            let path = PathBuf::from("/etc/systemd/network/").join(format!("22-ramona-{name}"));
            if path.exists() {
                fs::remove_file(path)?;
            }
        }
        network_units.replace_category("wireguard", units).await?;

        Ok(TaskResult::ScheduleAgainIn(Duration::from_mins(1)))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use nix::libc::IF_NAMESIZE;

    #[test]
    pub fn can_make_interface_name() {
        assert_eq!(make_interface_name("wg-", "a"), "wg-a");

        let long_string = "a".repeat(512);
        let long = make_interface_name("wg-", &long_string);

        assert_eq!(long.len(), IF_NAMESIZE - 1);
        assert_eq!(long, "wg-aaaaaaaaaaaa");

        let exact_match = make_interface_name("wg-", "abcdefghijkl");
        assert_eq!("wg-abcdefghijkl", exact_match)
    }
}
