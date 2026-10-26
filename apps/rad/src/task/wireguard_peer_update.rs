use crate::io::UpdateResult;
use crate::io::update_if_changed;
use crate::task::TaskContext;
use std::{
    collections::HashMap,
    fs::{self},
    process::{Command, Stdio},
    time::Duration,
};

use anyhow::Context;
use async_trait::async_trait;
use nix::libc::IF_NAMESIZE;
use tracing::{debug, info};

use crate::task::{Task, TaskResult};

#[derive(Debug)]
pub struct WireguardPeerUpdate {}

impl WireguardPeerUpdate {
    pub fn new() -> Self {
        Self {}
    }
}

fn make_interface_name(full_name: &str) -> String {
    assert!(!full_name.is_empty());

    let prefix = "wg-";
    let max_length = IF_NAMESIZE - prefix.len() - "\0".len();
    let name_offset = full_name.len().saturating_sub(max_length);

    format!("{prefix}{}", &full_name[name_offset..])
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

        let units: HashMap<String, String> = tunnels
            .into_iter()
            .flat_map(|tunnel| {
                // TODO let (remote, local) = tunnel.endpoints() maybe
                let remote_endpoint = tunnel.remote_endpoint(context.host_identity.hostname());
                let local_endpoint = tunnel.local_endpoint(context.host_identity.hostname());

                let peer_id_str = remote_endpoint.host_id().simple().to_string();
                let interface_name = make_interface_name(&peer_id_str);

                let netdev = (
                    format!(
                        "22-ramona-{}.netdev",
                        remote_endpoint.hostname().first_label()
                    ),
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
                    format!(
                        "22-ramona-{}.network",
                        remote_endpoint.hostname().first_label()
                    ),
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

        let mut needs_reload = false;
        for (filename, contents) in &units {
            if update_if_changed(format!("/etc/systemd/network/{filename}"), contents)?
                == UpdateResult::Changed
            {
                needs_reload = true;
            }
        }

        for existing in fs::read_dir("/etc/systemd/network/")? {
            let existing = existing?;

            if !existing
                .file_type()
                .with_context(|| format!("getting the type for {existing:?}"))?
                .is_file()
            {
                continue;
            }

            let file_name = existing.file_name();
            let file_name = file_name.to_string_lossy();

            if !file_name.starts_with("22-ramona-") {
                continue;
            }

            if !units.contains_key(file_name.as_ref()) {
                fs::remove_file(existing.path())
                    .with_context(|| format!("trying to remove {file_name:?}"))?;
                needs_reload = true;
            }
        }

        if needs_reload {
            let reload = Command::new("networkctl")
                .arg("reload")
                .stdout(Stdio::piped())
                .stderr(Stdio::piped())
                .spawn()?;
            let reload_result = reload.wait_with_output()?;

            info!(?reload_result, "wireguard config updated");
        }

        Ok(TaskResult::ScheduleAgainIn(Duration::from_mins(1)))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use nix::libc::IF_NAMESIZE;

    #[test]
    pub fn can_make_interface_name() {
        assert_eq!(make_interface_name("a"), "wg-a");

        let long_string = "a".repeat(512);
        let long = make_interface_name(&long_string);

        assert_eq!(long.len(), IF_NAMESIZE - 1);
        assert_eq!(long, "wg-aaaaaaaaaaaa");

        let exact_match = make_interface_name("abcdefghijkl");
        assert_eq!("wg-abcdefghijkl", exact_match)
    }
}
