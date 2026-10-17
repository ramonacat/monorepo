use axum::{Json, extract};
use rlib::ipam::{PostIpamAllocateRequest, PostIpamAllocateResponse};
use sqlx::Connection;

use crate::{AppState, services::ipam::allocate_cidr};

pub async fn post_allocate(
    extract::State(app_state): extract::State<AppState>,
    extract::Json(request): extract::Json<PostIpamAllocateRequest>,
) -> Json<PostIpamAllocateResponse> {
    let mut connection = app_state.db_connect().await;
    let (allocation_id, cidr) = connection
        .transaction(|tx| {
            Box::pin(async move {
                let allocation =
                    allocate_cidr(tx, request.parent_id, request.name, request.prefix_length)
                        .await?;

                Ok::<_, anyhow::Error>(allocation)
            })
        })
        .await
        .unwrap();

    Json(PostIpamAllocateResponse {
        allocation_id,
        cidr,
    })
}
