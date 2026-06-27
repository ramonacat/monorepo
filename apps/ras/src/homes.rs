use axum::{Json, extract, http::StatusCode};
use chrono::{DateTime, Utc};
use diesel::{
    BelongingToDsl, ExpressionMethods, GroupedBy, QueryDsl, SelectableHelper, insert_into,
    upsert::excluded,
};
use diesel_async::RunQueryDsl as _;
use serde::{Deserialize, Serialize};
use tracing::instrument;

use crate::{
    AppState,
    models::{HomeClosure, HomeClosureState},
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
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Homes {
    closures: Vec<HomeClosureDescription>,
    hosts: Vec<HomeHost>,
}

#[instrument]
#[axum::debug_handler]
pub async fn get_current_state(extract::State(app_state): extract::State<AppState>) -> Json<Homes> {
    use crate::schema::home_closure::dsl as hc;

    let mut connection = app_state.db_connect().await;
    let raw_closures: Vec<HomeClosure> = hc::home_closure.load(&mut connection).await.unwrap();

    let closures = raw_closures
        .iter()
        .map(|x| HomeClosureDescription {
            name: x.name.clone(),
            current_closure: x.current_closure.clone(),
            current_closure_updated_at: x.current_closure_updated_at,
        })
        .collect();

    let hosts = HomeClosureState::belonging_to(&raw_closures)
        .select(HomeClosureState::as_select())
        .load(&mut connection)
        .await
        .unwrap()
        .grouped_by(&raw_closures)
        .into_iter()
        .zip(raw_closures)
        .flat_map(|(states, closure)| {
            states
                .into_iter()
                .map(|state| HomeHost {
                    hostname: state.hostname,
                    closure_name: state.closure_name,
                    current_closure: state.current_closure,
                    current_closure_updated_at: state.current_closure_updated_at,
                    latest_closure: closure.current_closure.clone(),
                    latest_closure_updated_at: closure.current_closure_updated_at,
                })
                .collect::<Vec<_>>()
        })
        .collect();

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
    extract::Path(name_value): extract::Path<String>,
    extract::Json(request): extract::Json<PostLatestClosureRequest>,
) {
    use crate::schema::home_closure::dsl::*;

    let mut connection = app_state.db_connect().await;

    insert_into(home_closure)
        .values((
            name.eq(name_value),
            current_closure.eq(request.latest_closure),
            current_closure_updated_at.eq(Utc::now()),
        ))
        .on_conflict(name)
        .do_update()
        .set((
            current_closure.eq(excluded(current_closure)),
            current_closure_updated_at.eq(excluded(current_closure_updated_at)),
        ))
        .execute(&mut connection)
        .await
        .unwrap();
}

#[instrument]
#[axum::debug_handler]
pub async fn get_latest_closure(
    extract::State(app_state): extract::State<AppState>,
    extract::Path(name_value): extract::Path<String>,
) -> (StatusCode, String) {
    use crate::schema::home_closure::dsl::*;

    let mut connection = app_state.db_connect().await;

    let latest = home_closure
        .filter(name.eq(name_value))
        .first::<HomeClosure>(&mut connection)
        .await;

    match latest {
        Ok(latest) => (StatusCode::OK, latest.current_closure),
        Err(e) => match e {
            diesel::NotFound => (StatusCode::NOT_FOUND, String::new()),
            _ => panic!("failed to retrieve the latest closure: {e:?}"),
        },
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PostCurrentClosureRequest {
    current_closure: String,
}

#[instrument]
#[axum::debug_handler]
pub async fn post_current_closure(
    extract::State(app_state): extract::State<AppState>,
    extract::Path((name_value, hostname_value)): extract::Path<(String, String)>,
    extract::Json(request): extract::Json<PostCurrentClosureRequest>,
) {
    use crate::schema::home_closure_state::dsl::*;

    let mut connection = app_state.db_connect().await;

    insert_into(home_closure_state)
        .values((
            hostname.eq(hostname_value),
            closure_name.eq(name_value),
            current_closure.eq(request.current_closure),
            current_closure_updated_at.eq(Utc::now()),
        ))
        .on_conflict(hostname)
        .do_update()
        .set((
            closure_name.eq(excluded(closure_name)),
            current_closure.eq(excluded(current_closure)),
            current_closure_updated_at.eq(excluded(current_closure_updated_at)),
        ))
        .execute(&mut connection)
        .await
        .unwrap();
}
