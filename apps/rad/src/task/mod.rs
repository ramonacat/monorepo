use std::{fmt::Debug, time::Duration};

use async_trait::async_trait;
use rlib::{
    host_identity::HostIdentity,
    ras_client::{RasClient, RasConnectionConfig},
};

use crate::config::Configuration;

pub mod generate_bird_config;
pub mod host_state_update;
pub mod mikrotik_tunnel_update;
pub mod wireguard_peer_update;

#[derive(Debug)]
pub enum TaskResult {
    #[allow(unused)]
    Done,
    ScheduleAgainIn(Duration),
}

pub struct TaskContext<'a> {
    config: &'a Configuration,
    host_identity: &'a HostIdentity,
}

impl<'a> TaskContext<'a> {
    pub fn new(config: &'a Configuration, host_identity: &'a HostIdentity) -> Self {
        Self {
            config,
            host_identity,
        }
    }

    pub fn make_ras_client(&self) -> anyhow::Result<RasClient> {
        RasClient::new(RasConnectionConfig::MTls(self.host_identity.clone()))
    }
}

#[async_trait]
pub trait Task: Debug {
    async fn execute(&self, context: TaskContext<'_>) -> anyhow::Result<TaskResult>;
}
