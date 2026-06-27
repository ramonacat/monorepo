use axum::{Json, extract, http::StatusCode};
use chrono::{DateTime, Utc};
use diesel::{
    ExpressionMethods as _, insert_into, query_dsl::methods::FilterDsl, upsert::excluded,
};
use diesel_async::RunQueryDsl as _;
use serde::{Deserialize, Serialize};
use tracing::instrument;

use crate::{AppState, models::HostClosureState};

#[derive(Debug, Serialize, Deserialize)]
pub struct HostState {
    hostname: String,
    current_closure: Option<String>,
    current_closure_updated_at: Option<DateTime<Utc>>,
    latest_closure: Option<String>,
    latest_closure_updated_at: Option<DateTime<Utc>>,
    outdated: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CurrentStateResponse {
    hosts: Vec<HostState>,
}

#[axum::debug_handler]
pub async fn get_current_state(
    extract::State(app_state): extract::State<AppState>,
) -> Json<CurrentStateResponse> {
    use crate::schema::host_closure_state::dsl::*;

    let mut connection = app_state.db_connect().await;
    let states: Vec<HostClosureState> = host_closure_state.load(&mut connection).await.unwrap();

    let hosts = states
        .into_iter()
        .map(|x| HostState {
            outdated: x.latest_closure != x.current_closure,

            hostname: x.hostname,
            current_closure: x.current_closure,
            current_closure_updated_at: x.current_closure_updated_at,
            latest_closure: x.latest_closure,
            latest_closure_updated_at: x.latest_closure_updated_at,
        })
        .collect();

    Json(CurrentStateResponse { hosts })
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PostCurrentClosureRequest {
    current_closure: String,
}

#[axum::debug_handler]
#[instrument]
pub async fn post_current_closure(
    extract::State(app_state): extract::State<AppState>,
    extract::Path(hostname_value): extract::Path<String>,
    extract::Json(request): extract::Json<PostCurrentClosureRequest>,
) {
    use crate::schema::host_closure_state::dsl::*;

    let mut connection = app_state.db_connect().await;

    insert_into(host_closure_state)
        .values((
            hostname.eq(hostname_value),
            current_closure.eq(Some(request.current_closure)),
            current_closure_updated_at.eq(Some(Utc::now())),
        ))
        .on_conflict(hostname)
        .do_update()
        .set((
            current_closure.eq(excluded(current_closure)),
            current_closure_updated_at.eq(excluded(current_closure_updated_at)),
        ))
        .execute(&mut connection)
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
    extract::Path(hostname_value): extract::Path<String>,
    extract::Json(request): extract::Json<PostLatestClosureRequest>,
) {
    use crate::schema::host_closure_state::dsl::*;

    let mut connection = app_state.db_connect().await;

    insert_into(host_closure_state)
        .values((
            hostname.eq(hostname_value),
            latest_closure.eq(Some(request.latest_closure)),
            latest_closure_updated_at.eq(Some(Utc::now())),
        ))
        .on_conflict(hostname)
        .do_update()
        .set((
            latest_closure.eq(excluded(latest_closure)),
            latest_closure_updated_at.eq(excluded(latest_closure_updated_at)),
        ))
        .execute(&mut connection)
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
