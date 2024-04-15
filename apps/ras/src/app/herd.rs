use axum::{
    extract::{Path, State},
    http::StatusCode,
    Json,
};
use serde::Deserialize;

use super::AppState;

#[derive(Deserialize)]
pub struct PostHerdMachine {
    pub current_closure: String,
}

pub async fn post_herd_machine(
    State(state): State<AppState>,
    Path(hostname): Path<String>,
    Json(request): Json<PostHerdMachine>,
) -> Result<Json<String>, StatusCode> {
    state
        .herd_store
        .update_host(hostname, request.current_closure)
        .await;

    Ok(Json("OK".to_string()))
}
