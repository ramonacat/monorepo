use axum::{Json, extract};
use ipnet::IpNet;
use serde::{Deserialize, Serialize};
use sqlx::Connection;
use uuid::Uuid;

use crate::{AppState, services::ipam::allocate_cidr};

#[derive(Debug, Serialize, Deserialize)]
pub struct PostIpamAllocateRequest {
    parent_id: Uuid,
    name: String,
    prefix_length: u8,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PostIpamAllocateResponse {
    allocation_id: Uuid,
    cidr: IpNet,
}

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
