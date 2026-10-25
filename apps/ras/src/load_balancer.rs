use axum::{Json, extract};
use rlib::load_balancers::{PostUpsertRequest, PostUpsertResponse};
use sqlx::Connection;
use uuid::Uuid;

use crate::{AppState, services::load_balancer::upsert_load_balancer};

pub async fn post_upsert(
    extract::State(app_state): extract::State<AppState>,
    extract::Path(id): extract::Path<Uuid>,
    extract::Json(request): extract::Json<PostUpsertRequest>,
) -> Json<PostUpsertResponse> {
    let mut connection = app_state.db_connect().await;
    let ip = connection
        .transaction(|tx| {
            Box::pin(async move {
                let ip =
                    upsert_load_balancer(tx, id, request.host_group_id, &request.ports).await?;

                Ok::<_, anyhow::Error>(ip)
            })
        })
        .await
        .unwrap();

    Json(PostUpsertResponse { ip_address: ip })
}
