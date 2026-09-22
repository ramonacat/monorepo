mod config;
mod env;
mod host;
mod ras_client;
mod sensitive;
mod task;

use std::{
    ops::Add,
    time::{Duration, SystemTime},
};

use tokio::time::sleep;
use tracing::{error, info, warn};

use crate::task::{Task, host_state_update::HostStateUpdate};

const MAX_BACKOFF_STEPS: u32 = 8;

#[derive(Debug)]
struct TaskState {
    next_run_at: Option<SystemTime>,
    backoff_step: Option<u32>,
    task: Box<dyn Task>,
}

impl TaskState {
    fn new<T: Task + 'static>(task: T) -> Self {
        Self {
            next_run_at: Some(SystemTime::now()),
            backoff_step: None,
            task: Box::new(task),
        }
    }
}

#[tokio::main]
async fn main() {
    dotenvy::dotenv().ok();
    tracing_subscriber::fmt().init();

    let mut tasks = vec![TaskState::new(HostStateUpdate::new())];

    loop {
        let config = config::read().expect("failed to read configuration file");
        let host_identity =
            host::identity::read(&config).expect("failed to retrieve the host's identity");
        let now = SystemTime::now();

        for task in &mut tasks {
            if let Some(next_run_at) = task.next_run_at
                && next_run_at <= now
            {
                let result = task.task.execute(&config, &host_identity).await;

                match result {
                    Ok(t) => {
                        task.backoff_step = None;

                        match t {
                            task::TaskResult::Done => {
                                info!(?task, "task done");
                                task.next_run_at = None;
                            }
                            task::TaskResult::ScheduleAgainIn(duration) => {
                                info!(?task, "task scheduled again");

                                task.next_run_at = Some(now.add(duration));
                            }
                        }
                    }
                    Err(e) => {
                        warn!(?task, error=?e, "task failed");

                        let backoff_step = task.backoff_step.unwrap_or(0);
                        if backoff_step < MAX_BACKOFF_STEPS {
                            let delay = Duration::from_secs(2u64.pow(backoff_step));
                            task.next_run_at = Some(now.add(delay));
                            task.backoff_step = Some(backoff_step + 1);
                        } else {
                            error!(?task, "backoff limit reached");

                            panic!("backoff limit reached");
                        }
                    }
                }
            }
        }

        let done_tasks = tasks.extract_if(.., |x| x.next_run_at.is_none());

        for task in done_tasks {
            info!(?task, "task garbage collected");
        }

        // TODO it'd probably make sense to have some scheduling algorithm that sleeps for as long as needed, instead of rechecking the tasks every 10s
        sleep(Duration::from_secs(10)).await;
    }
}
