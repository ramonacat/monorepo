use axum::Json;
use std::sync::Arc;

use tokio::sync::Mutex;

pub mod events;
pub mod todos;

#[derive(Clone)]
pub struct AppState {
    pub todo_store: Arc<Mutex<crate::todo::store::Store>>,
    pub event_store: Arc<Mutex<crate::calendar::store::Store>>,
}

pub async fn index() -> Json<String> {
    Json("Hi".to_string())
}
