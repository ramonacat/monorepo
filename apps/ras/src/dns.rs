use std::time::Duration;

use axum::{Json, extract};
use serde::{Deserialize, Serialize};
use sqlx::Connection;
use uuid::Uuid;

use crate::AppState;

#[derive(Debug, Deserialize, Serialize)]
pub struct PostUpsertRequest {
    rrdatas: Vec<String>,
    ttl: Option<Duration>,
}

pub async fn post_upsert(
    extract::State(app_state): extract::State<AppState>,
    extract::Path((zone, record_name, record_type)): extract::Path<(String, String, String)>,
    extract::Json(request): extract::Json<PostUpsertRequest>,
) {
    let mut connection = app_state.db_connect().await;
    connection
        .transaction(|tx| {
            Box::pin(async move {
                crate::services::dns::upsert_record(
                    tx,
                    &zone,
                    &record_name,
                    &record_type,
                    &request.rrdatas,
                    request.ttl,
                )
                .await?;

                Ok::<_, anyhow::Error>(())
            })
        })
        .await
        .unwrap();
}

pub async fn delete(
    extract::State(app_state): extract::State<AppState>,
    extract::Path((zone, record_name, record_type)): extract::Path<(String, String, String)>,
) {
    let mut connection = app_state.db_connect().await;
    connection
        .transaction(|tx| {
            Box::pin(async move {
                crate::services::dns::delete_record(tx, &zone, &record_name, Some(&record_type))
                    .await?;

                Ok::<_, anyhow::Error>(())
            })
        })
        .await
        .unwrap();
}

pub async fn delete_by_name(
    extract::State(app_state): extract::State<AppState>,
    extract::Path((zone, record_name)): extract::Path<(String, String)>,
) {
    let mut connection = app_state.db_connect().await;
    connection
        .transaction(|tx| {
            Box::pin(async move {
                crate::services::dns::delete_record(tx, &zone, &record_name, None).await?;

                Ok::<_, anyhow::Error>(())
            })
        })
        .await
        .unwrap();
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Record {
    pub id: Uuid,
    pub name: String,
    pub r#type: String,
    pub rrdatas: Vec<String>,
    pub ttl: Option<Duration>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Zone {
    pub id: Uuid,
    pub name: String,
    pub serial: u32,
    pub refresh: Duration,
    pub retry: Duration,
    pub expire: Duration,
    pub negative_response_ttl: Duration,
    pub default_ttl: Duration,
    pub records: Vec<Record>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct GetAllZonesResponse {
    zones: Vec<Zone>,
}

pub async fn get_all_zones(
    extract::State(app_state): extract::State<AppState>,
) -> Json<GetAllZonesResponse> {
    let mut connection = app_state.db_connect().await;

    let zones = connection
        .transaction(|tx| {
            Box::pin(async move {
                let zones = crate::services::dns::get_all_zones(tx).await?;

                Ok::<_, anyhow::Error>(zones)
            })
        })
        .await
        .unwrap();

    Json(GetAllZonesResponse { zones })
}
