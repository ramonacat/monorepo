use std::{
    cmp::Reverse,
    collections::{HashMap, HashSet},
    fmt::Write as _,
    process::Command,
    time::Duration,
};

use anyhow::{Context, Ok};
use async_trait::async_trait;
use tracing::info;

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

        let mut frr_config = format!("bfd\nrouter ospf\n    ospf router-id {router_id}\n");

        // TODO this should probably be some sort of shared state that any task can access, as
        // host_state_update needs this as well
        let host_network_info = crate::host::networking::read(config).await?;
        let mut networks = config_routing.networks.clone();
        networks.sort_unstable_by_key(|x| Reverse(x.cidr.prefix_len()));

        for network in &networks {
            writeln!(&mut frr_config, "    network {} area 0.0.0.0", network.cidr)?;
        }

        for (interface, addresses) in
            host_network_info
                .addresses()
                .fold(HashMap::new(), |mut a, x| {
                    a.entry(&x.interface)
                        .or_insert_with(HashSet::new)
                        .insert(x.address);

                    a
                })
        {
            let Some(network) = networks
                .iter()
                .find(|x| addresses.iter().any(|y| x.cidr.contains(y)))
            else {
                info!(?interface, ?addresses, "no ospf config for ip");
                continue;
            };

            writeln!(
                &mut frr_config,
                // TODO only make the router tunnels ptp
                "interface {}\n    ip ospf cost {}\n    ip ospf bfd\n    ip ospf network point-to-point",
                interface, network.cost
            )?;
        }

        let update_result = update_if_changed(&config_routing.frr_config, &frr_config)
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
