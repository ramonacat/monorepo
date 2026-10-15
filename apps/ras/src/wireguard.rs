use axum::{Json, extract};
use rlib::{hosts::Hostname, wireguard::GetTunnelsResponse};
use sqlx::Connection;

use crate::{AppState, services::wireguard::get_tunnels_for_host};

pub async fn get_tunnels(
    state: extract::State<AppState>,
    extract::Path(hostname): extract::Path<String>,
) -> Json<GetTunnelsResponse> {
    let hostname = Hostname::new(hostname);
    let mut connection = state.db_connect().await;

    let tunnels = connection
        .transaction(|tx| Box::pin(async move { get_tunnels_for_host(tx, &hostname).await }))
        .await
        .unwrap();

    Json(GetTunnelsResponse { tunnels })
}
