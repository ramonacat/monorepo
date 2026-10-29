use askama::Template;
use std::process::Stdio;
use std::{process::Command, time::Duration};

use anyhow::{Context, Ok};
use async_trait::async_trait;
use tracing::{error, info};

use crate::bird::{ConfigTemplate, Interface};
use crate::task::TaskContext;
use crate::{
    io::{UpdateResult, update_if_changed},
    task::{Task, TaskResult},
};

#[derive(Debug)]
pub struct GenerateBirdConfig {}

impl GenerateBirdConfig {
    pub fn new() -> Self {
        Self {}
    }
}

#[async_trait]
impl Task for GenerateBirdConfig {
    async fn execute(&self, context: TaskContext<'_>) -> anyhow::Result<TaskResult> {
        let state = context.config.state();
        let Some(config_routing) = &context.config.routing else {
            info!("not a router");

            return Ok(TaskResult::ScheduleAgainIn(Duration::from_mins(1)));
        };

        let ras_client = context.make_ras_client()?;
        let router_id = state
            .with_async(async |x| {
                if let Some(router_id) = x.router_id {
                    return Ok(router_id);
                }

                let allocation = ras_client
                    .ip_allocate(
                        // TODO figure out how to avoid hardcoding the UUID?
                        uuid::uuid!("01a144a0-f8fb-7152-bcb0-7d1bca56042b"),
                        context.host_identity.hostname().first_label().to_string(),
                        // TODO this will break for ipv6
                        32,
                    )
                    .await?;

                let router_id = allocation.cidr.addr();
                x.router_id = Some(router_id);

                Ok(router_id)
            })
            .await?;

        let config_template = ConfigTemplate::new(
            router_id,
            config_routing.filter_import.clone(),
            config_routing.filter_export.clone(),
            config_routing
                .interfaces
                .iter()
                .map(|x| Interface::new(x.name_pattern.clone(), x.cost, x.is_tunnel))
                .collect(),
            config_routing.additional_config.clone(),
        );

        let update_result =
            update_if_changed(&config_routing.bird_config, &config_template.render()?)
                .await
                .with_context(|| format!("updating {:?}", config_routing.bird_config))?;

        if update_result == UpdateResult::Changed {
            let result = Command::new("/run/current-system/sw/bin/systemctl")
                .args(["reload", "bird.service"])
                .stdout(Stdio::piped())
                .stderr(Stdio::piped())
                .spawn()?
                .wait_with_output()?;

            if result.status.success() {
                info!(?result, "bird reloaded");
            } else {
                error!(?result, "failed to reload bird");
            }
        }

        Ok(TaskResult::ScheduleAgainIn(Duration::from_mins(1)))
    }
}
