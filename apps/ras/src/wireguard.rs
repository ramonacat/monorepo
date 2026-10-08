use axum::{Json, extract};
use ipnet::Ipv4Net;
use rlib::{hosts::Hostname, networking::is_global4, wireguard::GetTunnelsResponse};
use sqlx::Connection;

use crate::{AppState, services::wireguard::get_tunnels_for_host};

pub async fn get_tunnels(
    state: extract::State<AppState>,
    extract::Path(hostname): extract::Path<String>,
) -> Json<GetTunnelsResponse> {
    let hostname = Hostname::new(hostname);
    let mut connection = state.db_connect().await;

    let tunnels = connection
        .transaction(|tx| Box::pin(async move { get_tunnels_for_host(tx, &hostname).await }))
        .await
        .unwrap();

    let tunnels = tunnels
        .into_iter()
        .map(|x| rlib::wireguard::Tunnel {
            id: x.id,
            initiator: rlib::wireguard::TunnelHost {
                id: x.initiator.id,
                name: Hostname::new(x.initiator.name),
                public_key: x.initiator.public_key,
            },
            responder: rlib::wireguard::TunnelHost {
                id: x.responder.id,
                name: Hostname::new(x.responder.name),
                public_key: x.responder.public_key,
            },
            cidr: x.cidr,
            responder_port: x.responder_port,
            responder_ip: x
                .responder_ips
                .iter()
                .filter_map(|x| match x {
                    std::net::IpAddr::V4(ipv4_addr) => {
                        if is_global4(ipv4_addr) {
                            Some(ipnet::IpNet::V4(Ipv4Net::new(*ipv4_addr, 32).unwrap()))
                        } else {
                            None
                        }
                    }
                    std::net::IpAddr::V6(_) => None,
                })
                .next()
                .unwrap(),
        })
        .collect();

    Json(GetTunnelsResponse { tunnels })
}
