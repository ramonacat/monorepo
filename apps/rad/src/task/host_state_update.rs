use std::time::Duration;

use async_trait::async_trait;
use rlib::hosts::{ClosureUpdate, ConnectivityState, PostHostStateRequest};
use tracing::info;

use crate::{
    ras_client::RasClient,
    task::{Task, TaskResult},
};

#[derive(Debug)]
pub struct HostStateUpdate {}

impl HostStateUpdate {
    pub fn new() -> Self {
        Self {}
    }
}

#[async_trait]
impl Task for HostStateUpdate {
    async fn execute(
        &self,
        config: &crate::config::Configuration,
        host_identity: &crate::host::identity::HostIdentity,
    ) -> anyhow::Result<TaskResult> {
        let ras_client = RasClient::new(host_identity.clone()).unwrap();

        let host_network_info = crate::host::networking::read(config).await.unwrap();
        info!(?host_network_info, "collected host network information");

        let host_nixos_info = crate::host::nixos::read().unwrap();

        let request_body = PostHostStateRequest {
            connectivity: ConnectivityState {
                addresses: host_network_info.addresses().cloned().collect(),
                wireguard: host_network_info
                    .wireguard()
                    .map(|x| rlib::hosts::WireguardEndpoint {
                        public_key: x.key().to_public_base64(),
                        endpoint: x.endpoint(),
                    }),
            },
            closure: Some(ClosureUpdate {
                latest_closure: None,
                current_closure: Some(host_nixos_info.current_closure().to_string_lossy().into()),
            }),
        };

        ras_client.update_host_state(&request_body).await.unwrap();

        Ok(TaskResult::ScheduleAgainIn(Duration::from_mins(1)))
    }
}
