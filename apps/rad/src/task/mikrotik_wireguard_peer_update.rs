use std::time::Duration;

use async_trait::async_trait;
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

impl MikrotikWireguardPeerUpdate {}

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

        // TODO actually get the endpoints from ras, compare with what the router knows and update
        // as necessary
        let _ras_client = RasClient::new(host_identity.clone())?;

        let mut connection = Connection::connect(
            config.endpoint,
            &config.username,
            config.password.read()?.as_ref().map(|x| x.as_str()),
        )
        .await?;

        let peers = connection
            .send("interface/wireguard/peer/print", [], [])
            .await?;
        info!(?peers, "found current peers");

        Ok(TaskResult::ScheduleAgainIn(Duration::from_mins(1)))
    }
}
