use serde::{Deserialize, Serialize};
use std::time::Duration;
use uuid::Uuid;

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
pub struct PostUpsertRequest {
    pub rrdatas: Vec<String>,
    pub ttl: Option<Duration>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct GetAllZonesResponse {
    pub zones: Vec<Zone>,
}
