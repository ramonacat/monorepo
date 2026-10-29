use std::fmt::Write;
use std::process::Stdio;
use std::{collections::HashMap, time::Duration};

use askama::Template;
use async_trait::async_trait;
use ipnet::IpNet;
use rlib::load_balancers::GetByHostResponse;
use tokio::fs;
use tokio::process::Command;
use tracing::{error, info};

use crate::{
    linux::make_interface_name,
    systemd::NetworkUnits,
    task::{Task, TaskContext, TaskResult},
};

const NFT_RULES_PATH: &str = "/var/ramona/nft_rules";

#[derive(Debug)]
pub struct InstallLoadBalancers {}

impl InstallLoadBalancers {
    pub fn new() -> Self {
        Self {}
    }
}

#[async_trait]
impl Task for InstallLoadBalancers {
    async fn execute(&self, context: TaskContext<'_>) -> anyhow::Result<TaskResult> {
        let GetByHostResponse { balancers } = context
            .make_ras_client()?
            .get_load_balancers(context.host_identity.hostname())
            .await?;

        let mut units = HashMap::new();

        for balancer in &balancers {
            let name = make_interface_name("lb-", &balancer.ip.to_string());

            let netdev = NetdevTemplate { name: name.clone() };
            units.insert(format!("{}.netdev", balancer.ip), netdev.render()?);

            let network = NetworkTemplate {
                name,
                ip: match balancer.ip {
                    std::net::IpAddr::V4(ipv4_addr) => IpNet::new(ipv4_addr.into(), 32)?,
                    std::net::IpAddr::V6(ipv6_addr) => IpNet::new(ipv6_addr.into(), 128)?,
                },
            };
            units.insert(format!("{}.network", balancer.ip), network.render()?);
        }

        let network_units = NetworkUnits::new();
        network_units
            .replace_category("load_balancer", units)
            .await?;

        let mut rulefile = "add table ip ramona-lb\nflush table ip ramona-lb\n".to_string();
        writeln!(rulefile, "table ip ramona-lb {{")?;

        writeln!(rulefile, "chain incoming {{")?;
        writeln!(rulefile, "type nat hook input priority 0; policy accept;")?;
        for balancer in &balancers {
            for port in &balancer.ports {
                writeln!(
                    rulefile,
                    "ip daddr {} {} dport {} redirect to :{}",
                    balancer.ip,
                    match port.protocol {
                        rlib::load_balancers::ServiceProtocol::Tcp => "tcp",
                        rlib::load_balancers::ServiceProtocol::Udp => "udp",
                    },
                    port.exposed_port,
                    port.host_port
                )?;
            }
        }
        writeln!(rulefile, "}}")?;
        writeln!(rulefile, "}}")?;

        fs::write(NFT_RULES_PATH, rulefile).await?;

        let output = Command::new("nft")
            .args(["-f", NFT_RULES_PATH])
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()?
            .wait_with_output()
            .await?;

        if output.status.success() {
            info!(?output, "nft rules reloaded");
        } else {
            error!(?output, "nft rules reload failed");
        }

        Ok(TaskResult::ScheduleAgainIn(Duration::from_mins(1)))
    }
}

#[derive(Debug, Template)]
#[template(path = "load_balancer.netdev")]
struct NetdevTemplate {
    name: String,
}

#[derive(Debug, Template)]
#[template(path = "load_balancer.network")]
struct NetworkTemplate {
    name: String,
    ip: IpNet,
}
