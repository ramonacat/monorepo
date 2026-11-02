use axum::{Json, extract};
use rlib::dns::{GetAllZonesResponse, PostUpsertRequest};
use sqlx::Connection;

use crate::AppState;

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
