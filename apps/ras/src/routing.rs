use sqlx::Connection;
use std::net::IpAddr;

use axum::{Json, extract};
use ipnet::IpNet;
use rlib::hosts::Hostname;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::AppState;

#[derive(Debug, Serialize, Deserialize)]
pub struct Route {
    pub id: Uuid,
    pub target_hostname: Hostname,
    pub target_ips: Vec<IpAddr>,
    pub target_cidr: IpNet,
    pub blackhole: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct GetRoutesResponse {
    routes: Vec<Route>,
}

pub async fn get_routes(
    extract::State(app_state): extract::State<AppState>,
) -> Json<GetRoutesResponse> {
    let mut connection = app_state.db_connect().await;
    let routes = connection
        .transaction(|tx| Box::pin(async move { crate::services::routing::get_routes(tx).await }))
        .await
        .unwrap();

    Json(GetRoutesResponse { routes })
}

pub async fn post_routes(
    extract::State(app_state): extract::State<AppState>,
    extract::Json(request): extract::Json<Route>,
) {
    let mut connection = app_state.db_connect().await;
    connection
        .transaction(|tx| {
            Box::pin(async move { crate::services::routing::create_route(tx, request).await })
        })
        .await
        .unwrap();
}

pub async fn delete_routes_by_id(
    extract::State(app_state): extract::State<AppState>,
    extract::Path(id): extract::Path<Uuid>,
) {
    let mut connection = app_state.db_connect().await;
    connection
        .transaction(|tx| {
            Box::pin(async move { crate::services::routing::delete_route(tx, id).await })
        })
        .await
        .unwrap();
}
