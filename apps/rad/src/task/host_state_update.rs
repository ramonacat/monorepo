use std::time::Duration;

use async_trait::async_trait;
use rlib::hosts::{NetworkingState, NixosState, PostHostStateRequest, WireguardState};

use crate::task::{Task, TaskContext, TaskResult};

#[derive(Debug)]
pub struct HostStateUpdate {}

impl HostStateUpdate {
    pub fn new() -> Self {
        Self {}
    }
}

#[async_trait]
impl Task for HostStateUpdate {
    async fn execute(&self, context: TaskContext<'_>) -> anyhow::Result<TaskResult> {
        let ras_client = context.make_ras_client()?;

        let host_network_info = crate::host::networking::read(context.config).await?;
        let host_nixos_info = crate::host::nixos::read()?;

        let request_body = PostHostStateRequest {
            closure: Some(NixosState {
                current_closure: host_nixos_info.current_closure().to_string_lossy().into(),
            }),
            networking: Some(NetworkingState {
                addresses: host_network_info.addresses().cloned().collect(),
                wireguard: host_network_info.wireguard().map(|x| WireguardState {
                    listen_addresses: x.addresses().iter().map(|y| y.addr()).collect(),
                    available_ports: x.available_ports().to_vec(),
                    public_key: x.key().to_public_base64(),
                }),
            }),
            group_name: context.config.host_group_name.clone(),
        };

        ras_client
            .update_host_state(context.host_identity.hostname(), &request_body)
            .await?;

        Ok(TaskResult::ScheduleAgainIn(Duration::from_mins(1)))
    }
}
