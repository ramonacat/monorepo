use std::{fmt::Debug, time::Duration};

use async_trait::async_trait;

use crate::{config::Configuration, host::identity::HostIdentity};

pub mod host_state_update;

pub enum TaskResult {
    #[allow(unused)]
    Done,
    ScheduleAgainIn(Duration),
}

#[async_trait]
pub trait Task: Debug {
    async fn execute(
        &self,
        config: &Configuration,
        host_identity: &HostIdentity,
    ) -> anyhow::Result<TaskResult>;
}
