use crate::ras_client::RasClient;
use std::{
    collections::HashMap,
    fs::{self},
    io::{Read, Seek, SeekFrom, Write},
    path::Path,
    process::{Command, Stdio},
    time::Duration,
};

use async_trait::async_trait;
use tracing::{debug, info};

use crate::{
    config::Configuration,
    host::identity::HostIdentity,
    task::{Task, TaskResult},
};

#[derive(Debug)]
pub struct WireguardPeerUpdate {}

impl WireguardPeerUpdate {
    pub fn new() -> Self {
        Self {}
    }
}

#[async_trait]
impl Task for WireguardPeerUpdate {
    async fn execute(
        &self,
        config: &Configuration,
        host_identity: &HostIdentity,
    ) -> anyhow::Result<TaskResult> {
        let Some(wireguard_config) = &config.wireguard else {
            debug!("wireguard not enabled");

            return Ok(TaskResult::ScheduleAgainIn(Duration::from_mins(1)));
        };
        let ras_client = RasClient::new(host_identity.clone())?;
        let tunnels = ras_client
            .get_wireguard_tunnels_for_host(host_identity.hostname())
            .await?
            .tunnels;

        let units: HashMap<String, String> = tunnels
            .into_iter()
            .flat_map(|x| {
                let is_responder = &x.responder.name == host_identity.hostname();
                let peer = if is_responder {
                    &x.initiator
                } else {
                    &x.responder
                };

                let netdev = (
                    format!("22-ramona-{}.netdev", peer.name.first_label()),
                    format!(
                        "
                        [NetDev]
                        Name=wg-{peer_name}
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
                        peer_name = peer.name.first_label(),
                        private_key_file = wireguard_config.key_file.to_string_lossy(),
                        listen_port = if is_responder {
                            format!("ListenPort={}", x.responder_port)
                        } else {
                            String::new()
                        },
                        peer_public_key = peer.public_key,
                        endpoint = if is_responder {
                            String::new()
                        } else {
                            format!("Endpoint={}:{}", x.responder_ip, x.responder_port)
                        },
                    ),
                );

                let network = (
                    format!("22-ramona-{}.network", peer.name.first_label()),
                    format!(
                        "
                [Match]
                Name=wg-{peer_name}
                [LINK]
                ActivationPolicy=always-up
                Address={address}/{prefix_length}
                ",
                        peer_name = peer.name.first_label(),
                        address = (x
                            .cidr
                            .hosts()
                            .nth(if is_responder { 0 } else { 1 })
                            .unwrap()),
                        prefix_length = x.cidr.prefix_len()
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

            if !existing.file_type()?.is_file() {
                continue;
            }

            let file_name = existing.file_name();
            let file_name = file_name.to_string_lossy();

            if !file_name.starts_with("22-ramona-") {
                continue;
            }

            if !units.contains_key(file_name.as_ref()) {
                fs::remove_file(file_name.as_ref())?;
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

#[derive(Debug, PartialEq, Eq)]
enum UpdateResult {
    Changed,
    NotChanged,
}

fn update_if_changed(path: impl AsRef<Path>, contents: &str) -> anyhow::Result<UpdateResult> {
    let mut file = fs::OpenOptions::new()
        .read(true)
        .write(true)
        .create(true)
        .truncate(false)
        .open(path)?;
    let mut current_contents = String::new();
    file.read_to_string(&mut current_contents)?;

    if contents == current_contents {
        return Ok(UpdateResult::NotChanged);
    }

    file.set_len(0)?;
    file.seek(SeekFrom::Start(0))?;
    file.write_all(contents.as_bytes())?;

    Ok(UpdateResult::Changed)
}
