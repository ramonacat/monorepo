use axum::Json;
use std::sync::Arc;

use tokio::sync::Mutex;

use crate::maintenance::MonitoringMaintainer;

pub mod events;
pub mod maintenance;
pub mod todos;

#[derive(Clone)]
pub struct AppState {
    pub todo_store: Arc<Mutex<crate::todo::store::Store>>,
    pub event_store: Arc<Mutex<crate::calendar::store::Store>>,
    pub monitoring_maintainer: Arc<MonitoringMaintainer>,
}

pub async fn index() -> Json<String> {
    Json("Hi".to_string())
}
