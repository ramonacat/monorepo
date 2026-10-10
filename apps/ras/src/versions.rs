use axum::{Json, extract};
use serde::{Deserialize, Serialize};

use crate::AppState;

#[derive(Debug, Serialize, Deserialize)]
pub struct PostVersionRequest {
    versioned_item: String,
    store_path: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PostVersionResponse {
    version: i64,
    updated: bool,
    previous_store_path: Option<String>,
}

pub async fn post_version(
    extract::State(app_state): extract::State<AppState>,
    extract::Json(request): extract::Json<PostVersionRequest>,
) -> Json<PostVersionResponse> {
    let mut connection = app_state.db_connect().await;

    let latest = sqlx::query!("SELECT store_path, version FROM versions WHERE versioned_item=$1 ORDER BY version DESC LIMIT 1", request.versioned_item).fetch_optional(&mut connection).await.unwrap();

    let needs_update = latest
        .as_ref()
        .is_some_and(|x| x.store_path != request.store_path);
    let version = latest.as_ref().map_or(1, |x| x.version + 1);

    if needs_update {
        sqlx::query!(
            "
            INSERT INTO versions(versioned_item, store_path, version)
            VALUES ($1, $2, $3)
            ",
            request.versioned_item,
            request.store_path,
            latest.as_ref().map_or(1, |x| x.version + 1)
        )
        .execute(&mut connection)
        .await
        .unwrap();
    }

    Json(PostVersionResponse {
        version,
        updated: needs_update,
        previous_store_path: latest.map(|x| x.store_path),
    })
}

pub async fn post_version_check(
    extract::State(app_state): extract::State<AppState>,
    extract::Json(request): extract::Json<PostVersionRequest>,
) -> Json<PostVersionResponse> {
    let mut connection = app_state.db_connect().await;

    let latest = sqlx::query!("SELECT store_path, version FROM versions WHERE versioned_item=$1 ORDER BY version DESC LIMIT 1", request.versioned_item).fetch_optional(&mut connection).await.unwrap();

    let needs_update = latest
        .as_ref()
        .is_some_and(|x| x.store_path != request.store_path);
    let version = latest.as_ref().map_or(1, |x| x.version + 1);

    Json(PostVersionResponse {
        version,
        updated: needs_update,
        previous_store_path: latest.map(|x| x.store_path),
    })
}
