use crate::services::{ipam::update_live_ips, wireguard::update_wireguard};
use axum::{Json, extract, http::StatusCode};
use rlib::hosts::{HostState, Hostname, NixClosureState, PostHostStateRequest};
use serde::{Deserialize, Serialize};
use sqlx::{Connection, query};
use tracing::instrument;

use crate::{
    AppState,
    services::nixos::{ClosureName, StorePath, update_current_host_closure, update_latest_closure},
};

#[derive(Debug, Serialize, Deserialize)]
pub struct CurrentStateResponse {
    hosts: Vec<HostState>,
}

#[axum::debug_handler]
// TODO this is a bit messy, it's only used for grafana, probably we need to have a big think about
// how to actually do monitoring correctly
pub async fn get_current_state(
    extract::State(app_state): extract::State<AppState>,
) -> Json<CurrentStateResponse> {
    let mut connection = app_state.db_connect().await;

    let hosts = query!(
        "SELECT 
            h.name AS hostname,
            ncs.current_store_path AS current_closure,
            ncs.updated_at AS current_closure_updated_at,
            nc.latest_store_path AS latest_closure,
            nc.updated_at AS latest_closure_updated_at,
            (CASE WHEN nc.latest_store_path != ncs.current_store_path THEN 1 ELSE 0 END)::bool AS \"outdated!\"
        FROM host h
            LEFT JOIN nixos_closure_state ncs ON ncs.id=nixos_closure_state_id
            LEFT JOIN nixos_closure nc ON nc.id=ncs.closure_id
        "
    ).fetch_all(&mut connection).await.unwrap();

    // mapping manually as the nested structure is difficult/impossible to get right with `query_as!`
    let hosts = hosts
        .into_iter()
        .map(|x| HostState {
            hostname: x.hostname,
            current_closure: x.current_closure.clone(),
            current_closure_updated_at: x.current_closure_updated_at,
            latest_closure: x.latest_closure.clone(),
            latest_closure_updated_at: x.latest_closure_updated_at,
            outdated: x.outdated,
            nix_closure_state: if x.current_closure.is_some() || x.latest_closure.is_some() {
                Some(NixClosureState {
                    current_closure: x.current_closure,
                    current_closure_updated_at: x.current_closure_updated_at,
                    latest_closure: x.latest_closure,
                    latest_closure_updated_at: x.latest_closure_updated_at,
                    outdated: x.outdated,
                })
            } else {
                None
            },
        })
        .collect();
    Json(CurrentStateResponse { hosts })
}

#[axum::debug_handler]
#[instrument]
pub async fn post_host_state(
    extract::State(app_state): extract::State<AppState>,
    extract::Path(hostname): extract::Path<String>,
    extract::Json(request): extract::Json<PostHostStateRequest>,
) {
    let mut connection = app_state.db_connect().await;
    let hostname = Hostname::new(hostname);

    connection
        .transaction(|tx| {
            Box::pin(async move {
                if let Some(closure_update) = request.closure {
                    update_current_host_closure(
                        tx,
                        &hostname,
                        StorePath::new(closure_update.current_closure),
                    )
                    .await?;
                }

                if let Some(networking) = request.networking {
                    update_live_ips(tx, &hostname, networking.addresses).await?;
                    update_wireguard(tx, &hostname, networking.wireguard).await?;
                }

                Ok::<(), anyhow::Error>(())
            })
        })
        .await
        .unwrap();
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PostCurrentClosureRequest {
    current_closure: String,
}

#[axum::debug_handler]
#[instrument]
pub async fn post_current_closure(
    extract::State(app_state): extract::State<AppState>,
    extract::Path(hostname): extract::Path<String>,
    extract::Json(request): extract::Json<PostCurrentClosureRequest>,
) {
    let mut connection = app_state.db_connect().await;
    let hostname = Hostname::new(hostname);

    connection
        .transaction(|tx| {
            Box::pin(async move {
                update_latest_closure(
                    tx,
                    ClosureName::from_host(&hostname),
                    StorePath::new(request.current_closure),
                )
                .await?;

                Ok::<(), sqlx::Error>(())
            })
        })
        .await
        .unwrap();
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PostLatestClosureRequest {
    latest_closure: String,
}

#[axum::debug_handler]
#[instrument]
pub async fn post_latest_closure(
    extract::State(app_state): extract::State<AppState>,
    extract::Path(hostname): extract::Path<String>,
    extract::Json(request): extract::Json<PostLatestClosureRequest>,
) {
    let mut connection = app_state.db_connect().await;
    let hostname = Hostname::new(hostname);

    connection
        .transaction(|tx| {
            Box::pin(async move {
                update_latest_closure(
                    tx,
                    ClosureName::from_host(&hostname),
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
    extract::Path(hostname): extract::Path<String>,
) -> (StatusCode, String) {
    let mut connection = app_state.db_connect().await;
    let hostname = Hostname::new(hostname);

    let store_path = connection
        .transaction(|tx| {
            Box::pin(async move {
                crate::services::nixos::get_latest_closure(tx, ClosureName::from_host(&hostname))
                    .await
            })
        })
        .await
        .unwrap();

    (StatusCode::OK, store_path.raw().to_string())
}

#[instrument]
#[axum::debug_handler]
pub async fn delete(
    extract::State(app_state): extract::State<AppState>,
    extract::Path(hostname_value): extract::Path<String>,
) {
}
