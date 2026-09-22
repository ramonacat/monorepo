mod config;
mod env;
mod host;
mod ras_client;

use std::time::Duration;

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
        let host_identity = host::identity::read(&config).unwrap();
        let ras_client = RasClient::new(host_identity).unwrap();

        let host_network_info = host::networking::read(&config).await.unwrap();
        info!(?host_network_info, "collected host network information");

        let host_nixos_info = host::nixos::read().unwrap();

        let request_body = PostHostStateRequest {
            connectivity: ConnectivityState {
                addresses: host_network_info.addresses().cloned().collect(),
                wireguard: host_network_info
                    .wireguard()
                    .map(|x| rlib::hosts::WireguardEndpoint {
                        public_key: x.key().to_public_base64(),
                        endpoint: x.endpoint(),
                    }),
            },
            closure: Some(ClosureUpdate {
                latest_closure: None,
                current_closure: Some(host_nixos_info.current_closure().to_string_lossy().into()),
            }),
        };

        ras_client.update_host_state(&request_body).await.unwrap();

        sleep(Duration::from_secs(60)).await;
    }
}
