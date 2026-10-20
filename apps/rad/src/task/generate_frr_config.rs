use askama::Template;
use std::{process::Command, time::Duration};

use anyhow::{Context, Ok};
use async_trait::async_trait;
use tracing::info;

use crate::frr::ConfigTemplate;
use crate::{
    config::Configuration,
    host::identity::HostIdentity,
    io::{UpdateResult, update_if_changed},
    ras_client::RasClient,
    task::{Task, TaskResult},
};

#[derive(Debug)]
pub struct GenerateFrrConfig {}

impl GenerateFrrConfig {
    pub fn new() -> Self {
        Self {}
    }
}

#[async_trait]
impl Task for GenerateFrrConfig {
    async fn execute(
        &self,
        config: &Configuration,
        host_identity: &HostIdentity,
    ) -> anyhow::Result<TaskResult> {
        let state = config.state();
        let Some(config_routing) = &config.routing else {
            info!("not a router");

            return Ok(TaskResult::ScheduleAgainIn(Duration::from_mins(1)));
        };

        let ras_client = RasClient::new(host_identity.clone())?;
        let router_id = state
            .with_async(async |x| {
                if let Some(router_id) = x.router_id {
                    return Ok(router_id);
                }

                let allocation = ras_client
                    .ip_allocate(
                        // TODO figure out how to avoid hardcoding the UUID?
                        uuid::uuid!("01a144a0-f8fb-7152-bcb0-7d1bca56042b"),
                        host_identity.hostname().first_label().to_string(),
                        // TODO this will break for ipv6
                        32,
                    )
                    .await?;

                let router_id = allocation.cidr.addr();
                x.router_id = Some(router_id);

                Ok(router_id)
            })
            .await?;

        // TODO this should probably be some sort of shared state that any task can access, as
        // host_state_update needs this as well
        let host_network_info = crate::host::networking::read(config).await?;

        let interfaces = host_network_info
            .addresses()
            .filter_map(|address| {
                for interface_definition in &config_routing.interfaces {
                    if interface_definition.name_regex.is_match(&address.interface) {
                        return Some(crate::frr::Interface::new(
                            address.interface.clone(),
                            interface_definition.cost,
                            interface_definition.is_tunnel,
                        ));
                    }
                }

                info!(?address, "interface in network but not defined");
                None
            })
            .collect();

        let config_template =
            ConfigTemplate::new(router_id, config_routing.denied.clone(), interfaces);

        let update_result =
            update_if_changed(&config_routing.frr_config, &config_template.render()?)
                .with_context(|| format!("updating {:?}", config_routing.frr_config))?;

        if update_result == UpdateResult::Changed {
            Command::new("/run/current-system/sw/bin/systemctl")
                .args(["reload", "frr.service"])
                .spawn()?
                .wait()?;
        }

        Ok(TaskResult::ScheduleAgainIn(Duration::from_mins(1)))
    }
}
