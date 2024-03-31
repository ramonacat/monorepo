use axum::{extract::State, http::StatusCode, Json};
use tracing::error;

use super::AppState;

pub async fn post_monitoring(State(state): State<AppState>) -> Result<Json<String>, StatusCode> {
    if let Err(e) = state.monitoring_maintainer.execute().await {
        error!("Monitoring maintenance failed: {e}");

        return Err(StatusCode::INTERNAL_SERVER_ERROR);
    }

    Ok(Json("OK".to_string()))
}
