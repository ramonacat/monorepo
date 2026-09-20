mod model;

use std::collections::{HashMap, HashSet};

use axum::{Json, extract, http::StatusCode};
use diesel::{ExpressionMethods as _, query_dsl::methods::FilterDsl};
use diesel_async::RunQueryDsl as _;
use rlib::hosts::{
    ConnectivityState, HostState, NixClosureState, PostHostStateRequest, UDPEndpoint,
    WireguardEndpoint,
};
use serde::{Deserialize, Serialize};
use tracing::instrument;

use crate::{
    AppState,
    hosts::model::{
        delete_wireguard_endpoint, update_addresses, update_closure, update_wireguard_endpoint,
    },
    models::{HostClosureState, HostIpAddress},
};

#[derive(Debug, Serialize, Deserialize)]
pub struct CurrentStateResponse {
    hosts: Vec<HostState>,
}

#[axum::debug_handler]
pub async fn get_current_state(
    extract::State(app_state): extract::State<AppState>,
) -> Json<CurrentStateResponse> {
    let mut connection = app_state.db_connect().await;

    let mut closures: HashMap<_, _> = {
        use crate::schema::host_closure_state::dsl::*;

        let states: Vec<HostClosureState> = host_closure_state.load(&mut connection).await.unwrap();

        states
            .into_iter()
            .map(|x| {
                (
                    x.hostname,
                    NixClosureState {
                        outdated: x.latest_closure != x.current_closure,

                        current_closure: x.current_closure,
                        current_closure_updated_at: x.current_closure_updated_at,
                        latest_closure: x.latest_closure,
                        latest_closure_updated_at: x.latest_closure_updated_at,
                    },
                )
            })
            .collect()
    };

    let mut addresses: HashMap<_, _> = {
        use crate::schema::host_ip_address::dsl::*;

        let all_addresses: Vec<HostIpAddress> =
            host_ip_address.load(&mut connection).await.unwrap();

        let mut addresses_per_host = HashMap::new();
        for an_address in all_addresses {
            addresses_per_host
                .entry(an_address.hostname)
                .or_insert_with(Vec::new)
                .push(an_address.address);
        }

        addresses_per_host
    };

    let mut wireguard_endpoints: HashMap<_, _> = {
        use crate::schema::wireguard_endpoint::dsl::*;

        let all_endpoints: Vec<crate::models::WireguardEndpoint> =
            wireguard_endpoint.load(&mut connection).await.unwrap();

        all_endpoints
            .into_iter()
            .map(|x| {
                let udp_endpoint = x
                    .endpoint
                    .map(|y| UDPEndpoint::new(y, x.port.unwrap().try_into().unwrap()));
                (
                    x.hostname,
                    WireguardEndpoint {
                        public_key: x.public_key,
                        endpoint: udp_endpoint,
                    },
                )
            })
            .collect()
    };

    // TODO there should be a table listing all the hosts
    let hostnames: HashSet<String> = closures
        .keys()
        .chain(wireguard_endpoints.keys())
        .chain(addresses.keys())
        .cloned()
        .collect();
    let hosts = hostnames
        .into_iter()
        .map(|hostname| {
            let closure_state = closures.remove(&hostname);
            let connectivity = ConnectivityState {
                addresses: addresses.remove(&hostname).unwrap_or_default(),
                wireguard: wireguard_endpoints.remove(&hostname),
            };

            HostState {
                hostname,
                current_closure: closure_state
                    .as_ref()
                    .and_then(|x| x.current_closure.clone()),
                current_closure_updated_at: closure_state
                    .as_ref()
                    .and_then(|x| x.current_closure_updated_at),
                latest_closure: closure_state
                    .as_ref()
                    .and_then(|x| x.latest_closure.clone()),
                latest_closure_updated_at: closure_state
                    .as_ref()
                    .and_then(|x| x.latest_closure_updated_at),
                outdated: closure_state.as_ref().map(|x| x.outdated).unwrap_or(false),
                connectivity,
                nix_closure_state: closure_state,
            }
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

    if let Some(closure_update) = request.closure {
        update_closure(
            &mut connection,
            &hostname,
            closure_update.current_closure,
            closure_update.latest_closure,
        )
        .await
        .unwrap();
    }

    update_addresses(&mut connection, &hostname, request.connectivity.addresses)
        .await
        .unwrap();

    if let Some(wireguard) = request.connectivity.wireguard.as_ref() {
        update_wireguard_endpoint(
            &mut connection,
            hostname,
            &wireguard.public_key,
            wireguard.endpoint.as_ref(),
        )
        .await
        .unwrap();
    } else {
        delete_wireguard_endpoint(&mut connection, &hostname)
            .await
            .unwrap();
    }
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

    update_closure(
        &mut connection,
        &hostname,
        Some(request.current_closure),
        None,
    )
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

    update_closure(
        &mut connection,
        &hostname,
        None,
        Some(request.latest_closure),
    )
    .await
    .unwrap();
}

#[instrument]
#[axum::debug_handler]
pub async fn get_latest_closure(
    extract::State(app_state): extract::State<AppState>,
    extract::Path(hostname_value): extract::Path<String>,
) -> (StatusCode, String) {
    use crate::schema::host_closure_state::dsl::*;

    let mut connection = app_state.db_connect().await;

    let latest = host_closure_state
        .filter(hostname.eq(hostname_value))
        .first::<HostClosureState>(&mut connection)
        .await;

    match latest {
        Ok(latest) => latest.latest_closure.map_or_else(
            || (StatusCode::NOT_FOUND, String::new()),
            |ok| (StatusCode::OK, ok),
        ),
        Err(e) => match e {
            diesel::NotFound => (StatusCode::NOT_FOUND, String::new()),
            _ => panic!("failed to retrieve the latest closure: {e:?}"),
        },
    }
}

#[instrument]
#[axum::debug_handler]
pub async fn delete(
    extract::State(app_state): extract::State<AppState>,
    extract::Path(hostname_value): extract::Path<String>,
) {
    use crate::schema::host_closure_state::dsl::*;

    let mut connection = app_state.db_connect().await;
    diesel::delete(host_closure_state.filter(hostname.eq(hostname_value)))
        .execute(&mut connection)
        .await
        .unwrap();
}
