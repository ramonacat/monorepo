use ipnet::IpNet;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Serialize, Deserialize)]
pub struct PostIpamAllocateRequest {
    pub parent_id: Uuid,
    pub name: String,
    pub prefix_length: u8,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PostIpamAllocateResponse {
    pub allocation_id: Uuid,
    pub cidr: IpNet,
}
