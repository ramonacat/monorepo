use std::fmt::Write as _;
use std::{process::Command, time::Duration};

use anyhow::{Context, Ok};
use async_trait::async_trait;
use tracing::{info, warn};

use crate::{
    config::{Configuration, RoutingInterface},
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

        for network in &config_routing.networks {
            writeln!(&mut frr_config, "    network {} area 0.0.0.0", network)?;
        }

        let default_interface_definition = RoutingInterface {
            name_regex: regex::regex!("").clone(),
            cost: 100000,
            is_tunnel: false,
        };
        let routed_interfaces = host_network_info.addresses().filter_map(|address| {
            if !config_routing
                .networks
                .iter()
                .any(|y| y.contains(&address.address))
            {
                return None;
            }

            for interface_definition in &config_routing.interfaces {
                if interface_definition.name_regex.is_match(&address.interface) {
                    return Some((address.interface.clone(), interface_definition));
                }
            }

            warn!(?address, "interface in network but not defined");
            Some((address.interface.clone(), &default_interface_definition))
        });

        for (interface, definition) in routed_interfaces {
            writeln!(
                &mut frr_config,
                // TODO only make the router tunnels ptp
                "interface {}\n    ip ospf cost {}\n    ip ospf bfd\n{}",
                interface,
                definition.cost,
                if definition.is_tunnel {
                    "\n    ip ospf network point-to-point"
                } else {
                    ""
                }
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
