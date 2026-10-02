use crate::ras_client::RasClient;
use std::{
    fs,
    io::{Read, Seek, SeekFrom, Write},
    path::Path,
    process::{Command, Stdio},
    time::Duration,
};

use async_trait::async_trait;
use rlib::wireguard::WIREGUARD_PORT_DEFAULT;
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
        let mut endpoints = ras_client.get_wireguard_endpoints().await?.endpoints;
        endpoints.remove(host_identity.hostname());

        let peers = endpoints
            .into_iter()
            .map(|(name, description)| {
                format!(
                    "[WireGuardPeer]
# {name}
PublicKey={peer_public_key}
AllowedIPs=0.0.0.0/0,::/0
{endpoint_line}
PersistentKeepalive=25",
                    peer_public_key = description.public_key,
                    endpoint_line = description
                        .endpoint
                        .map_or_else(String::new, |x| format!("Endpoint={x}\n"))
                )
            })
            .fold(String::new(), |a, x| format!("{a}\n{x}"));

        let netdev_unit = format!(
            "[NetDev]
Name=wg-ramona0
Kind=wireguard
[WireGuard]
PrivateKeyFile={private_key_file}
ListenPort={listen_port}
{peers}",
            private_key_file = wireguard_config.key_file.to_string_lossy(),
            listen_port = match wireguard_config.endpoint {
                crate::config::WireguardEndpoint::InitiatorOnly
                | crate::config::WireguardEndpoint::Auto => WIREGUARD_PORT_DEFAULT,
                crate::config::WireguardEndpoint::Specified { host: _, port } => port,
            }
        );

        let network_unit = "
[Match]
Name=wg-ramona0
[LINK]
ActivationPolicy=always-up
"
        .to_string();

        let netdev_update =
            update_if_changed("/etc/systemd/network/22-ramona-wg.netdev", netdev_unit)?;
        let network_update =
            update_if_changed("/etc/systemd/network/22-ramona-wg.network", network_unit)?;

        if netdev_update == UpdateResult::Changed || network_update == UpdateResult::Changed {
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

fn update_if_changed(path: impl AsRef<Path>, contents: String) -> anyhow::Result<UpdateResult> {
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
