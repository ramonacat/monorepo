use axum::{Json, extract, http::StatusCode};
use chrono::{DateTime, Utc};
use rlib::hosts::Hostname;
use serde::{Deserialize, Serialize};
use sqlx::Connection;
use tracing::instrument;

use crate::{
    AppState,
    services::nixos::{ClosureName, StorePath, update_current_home_closure, update_latest_closure},
};

#[derive(Debug, Serialize, Deserialize)]
struct HomeClosureDescription {
    name: String,
    current_closure: String,
    current_closure_updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
struct HomeHost {
    hostname: String,
    closure_name: String,
    current_closure: String,
    current_closure_updated_at: DateTime<Utc>,
    latest_closure: String,
    latest_closure_updated_at: DateTime<Utc>,
    outdated: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Homes {
    closures: Vec<HomeClosureDescription>,
    hosts: Vec<HomeHost>,
}

#[instrument]
#[axum::debug_handler]
// TODO this is a bit messy, it's only used for grafana, probably we need to have a big think about
// how to actually do monitoring correctly
pub async fn get_current_state(extract::State(app_state): extract::State<AppState>) -> Json<Homes> {
    let mut connection = app_state.db_connect().await;

    let closures = sqlx::query_as!(
        HomeClosureDescription,
        "
        SELECT 
            nc.name AS name,
            ncs.current_store_path as current_closure,
            ncs.updated_at as current_closure_updated_at
        FROM nixos_closure_state ncs
        INNER JOIN nixos_closure nc ON nc.id = ncs.closure_id
        WHERE nc.name LIKE 'home:%'
    "
    )
    .fetch_all(&mut connection)
    .await
    .unwrap();

    let hosts = sqlx::query_as!(
        HomeHost,
        "
        SELECT 
            h.hostname AS hostname,
            nc.name AS closure_name,
            ncs.current_store_path AS current_closure,
            ncs.updated_at AS current_closure_updated_at,
            nc.latest_store_path AS latest_closure,
            nc.updated_at AS latest_closure_updated_at,
            (nc.latest_store_path != ncs.current_store_path) AS \"outdated!\"
        FROM home h
            INNER JOIN nixos_closure_state ncs ON ncs.id = h.nixos_closure_state_id
            INNER JOIN nixos_closure nc ON nc.id = ncs.closure_id
    "
    )
    .fetch_all(&mut connection)
    .await
    .unwrap();

    Json(Homes { closures, hosts })
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PostLatestClosureRequest {
    latest_closure: String,
}

#[instrument]
#[axum::debug_handler]
pub async fn post_latest_closure(
    extract::State(app_state): extract::State<AppState>,
    extract::Path(name): extract::Path<String>,
    extract::Json(request): extract::Json<PostLatestClosureRequest>,
) {
    let mut connection = app_state.db_connect().await;

    connection
        .transaction(|tx| {
            Box::pin(async move {
                update_latest_closure(
                    tx,
                    ClosureName::from_home(&name),
                    StorePath::new(request.latest_closure),
                )
                .await?;

                Ok::<(), sqlx::Error>(())
            })
        })
        .await
        .unwrap();
}

#[instrument]
#[axum::debug_handler]
pub async fn get_latest_closure(
    extract::State(app_state): extract::State<AppState>,
    extract::Path(name): extract::Path<String>,
) -> (StatusCode, String) {
    let mut connection = app_state.db_connect().await;

    let home = connection
        .transaction(|tx| {
            Box::pin(async move {
                crate::services::nixos::get_latest_closure(tx, ClosureName::from_home(&name)).await
            })
        })
        .await
        .unwrap();

    (StatusCode::OK, home.raw().to_string())
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PostCurrentClosureRequest {
    current_closure: String,
}

#[instrument]
#[axum::debug_handler]
pub async fn post_current_closure(
    extract::State(app_state): extract::State<AppState>,
    extract::Path((name, hostname)): extract::Path<(String, String)>,
    extract::Json(request): extract::Json<PostCurrentClosureRequest>,
) {
    let mut connection = app_state.db_connect().await;
    let home_name = ClosureName::from_home(&name);
    let hostname = Hostname::new(hostname);

    connection
        .transaction(|tx| {
            Box::pin(async move {
                update_current_home_closure(
                    tx,
                    &home_name,
                    &hostname,
                    StorePath::new(request.current_closure),
                )
                .await?;
                Ok::<(), sqlx::Error>(())
            })
        })
        .await
        .unwrap();
}
