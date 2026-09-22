mod config;
mod env;
mod host_identity;
mod host_networking;
mod ras_client;

use std::{fs, time::Duration};

use rlib::hosts::{ClosureUpdate, ConnectivityState, PostHostStateRequest};
use tokio::time::sleep;
use tracing::info;

use crate::ras_client::RasClient;

#[tokio::main]
async fn main() {
    dotenvy::dotenv().ok();
    tracing_subscriber::fmt().init();

    loop {
        let config = config::read().unwrap();
        let host_identity = host_identity::read(&config).unwrap();
        let ras_client = RasClient::new(host_identity).unwrap();

        let host_network_info = host_networking::read().unwrap();

        let current_closure = fs::canonicalize("/run/current-system").unwrap();
        info!(?host_network_info, "collected host network information");

        let endpoint = host_network_info
            .resolve_wireguard_endpoint(&config.wireguard.endpoint)
            .await
            .unwrap();
        let wireguard_key = host_networking::wireguard::Key::load(&config.wireguard).unwrap();

        let request_body = PostHostStateRequest {
            connectivity: ConnectivityState {
                addresses: host_network_info.addresses().cloned().collect(),
                wireguard: endpoint.map(|x| rlib::hosts::WireguardEndpoint {
                    public_key: wireguard_key.to_public_base64(),
                    endpoint: Some(x),
                }),
            },
            closure: Some(ClosureUpdate {
                latest_closure: None,
                current_closure: Some(current_closure.to_string_lossy().into()),
            }),
        };

        ras_client.update_host_state(&request_body).await.unwrap();

        sleep(Duration::from_secs(60)).await;
    }
}
