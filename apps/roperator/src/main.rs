#![deny(clippy::all, clippy::pedantic, clippy::nursery, warnings)]

mod gateway;
mod load_balancer;

use serde::Deserialize;
use tracing::info;
use uuid::Uuid;

use kube::Client;
use rlib::ras_client::{RasClient, RasConnectionConfig};

#[derive(Debug, Deserialize)]
struct Config {
    host_group_id: Uuid,
    dns_zones: Vec<String>,
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt().init();
    rustls::crypto::aws_lc_rs::default_provider()
        .install_default()
        .unwrap();

    let ras_client = RasClient::new(RasConnectionConfig::LocalUnencrypted).unwrap();

    let client = Client::try_default().await.unwrap();

    let lb_controller = load_balancer::controller(ras_client.clone(), client.clone());
    let gateway_controller = gateway::controller(ras_client, client);

    tokio::join!(lb_controller, gateway_controller);

    info!("terminating");
}
