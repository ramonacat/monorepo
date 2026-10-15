use std::net::{IpAddr, SocketAddr};

use crate::{hosts::Hostname, networking::is_global4};
use ipnet::IpNet;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Serialize, Deserialize)]
pub struct Initiator {
    host_id: Uuid,
    name: Hostname,
    public_key: String,
}

impl Initiator {
    pub fn new(host_id: Uuid, name: Hostname, public_key: String) -> Self {
        Self {
            host_id,
            name,
            public_key,
        }
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Responder {
    host_id: Uuid,
    name: Hostname,
    public_key: String,
    endpoints: Vec<SocketAddr>,
}

impl Responder {
    pub fn new(
        host_id: Uuid,
        name: Hostname,
        public_key: String,
        endpoints: Vec<SocketAddr>,
    ) -> Self {
        Self {
            host_id,
            name,
            public_key,
            endpoints,
        }
    }

    pub fn endpoint(&self) -> Option<SocketAddr> {
        // TODO support ipv6
        self.endpoints
            .iter()
            .filter(
                |x| matches!(x, SocketAddr::V4(socket_addr_v4) if is_global4(socket_addr_v4.ip())),
            )
            .copied()
            .next()
    }
}

pub enum LocalEndpoint<'tunnel> {
    Initiator(&'tunnel Initiator, IpNet),
    Responder(&'tunnel Responder, IpNet),
}

impl LocalEndpoint<'_> {
    pub fn as_responder(&self) -> Option<&Responder> {
        match self {
            LocalEndpoint::Initiator(_, _) => None,
            LocalEndpoint::Responder(responder, _) => Some(responder),
        }
    }

    pub fn public_key(&self) -> &str {
        match self {
            LocalEndpoint::Initiator(initiator, _) => &initiator.public_key,
            LocalEndpoint::Responder(responder, _) => &responder.public_key,
        }
    }

    pub fn tunnel_ip(&self) -> IpNet {
        match self {
            LocalEndpoint::Initiator(_, ip_addr) => *ip_addr,
            LocalEndpoint::Responder(_, ip_addr) => *ip_addr,
        }
    }
}

pub enum RemoteEndpoint<'tunnel> {
    Initiator(&'tunnel Initiator, IpAddr),
    Responder(&'tunnel Responder, IpAddr),
}

impl RemoteEndpoint<'_> {
    pub fn host_id(&self) -> Uuid {
        match self {
            RemoteEndpoint::Initiator(initiator, _) => initiator.host_id,
            RemoteEndpoint::Responder(responder, _) => responder.host_id,
        }
    }

    pub fn hostname(&self) -> &Hostname {
        match self {
            RemoteEndpoint::Initiator(initiator, _) => &initiator.name,
            RemoteEndpoint::Responder(responder, _) => &responder.name,
        }
    }

    pub fn public_key(&self) -> &str {
        match self {
            RemoteEndpoint::Initiator(initiator, _) => &initiator.public_key,
            RemoteEndpoint::Responder(responder, _) => &responder.public_key,
        }
    }

    pub fn is_responder(&self) -> bool {
        match self {
            RemoteEndpoint::Initiator(_, _) => false,
            RemoteEndpoint::Responder(_, _) => true,
        }
    }

    pub fn as_responder(&self) -> Option<&Responder> {
        match self {
            RemoteEndpoint::Initiator(_, _) => None,
            RemoteEndpoint::Responder(responder, _) => Some(responder),
        }
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Tunnel {
    id: Uuid,
    initiator: Initiator,
    responder: Responder,
    cidr: IpNet,
}

impl Tunnel {
    pub fn new(id: Uuid, initiator: Initiator, responder: Responder, cidr: IpNet) -> Self {
        Self {
            id,
            initiator,
            responder,
            cidr,
        }
    }

    pub fn remote_endpoint<'a>(&'a self, local_hostname: &Hostname) -> RemoteEndpoint<'a> {
        let mut tunnel_ip_range = self.cidr.hosts();

        if self.initiator.name.first_label() == local_hostname.first_label() {
            RemoteEndpoint::Responder(&self.responder, tunnel_ip_range.next().unwrap())
        } else {
            RemoteEndpoint::Initiator(&self.initiator, tunnel_ip_range.last().unwrap())
        }
    }

    pub fn local_endpoint(&self, local_hostname: &Hostname) -> LocalEndpoint<'_> {
        let mut tunnel_ip_range = self.cidr.hosts();

        if self.initiator.name.first_label() == local_hostname.first_label() {
            LocalEndpoint::Initiator(
                &self.initiator,
                IpNet::new_assert(tunnel_ip_range.last().unwrap(), self.cidr.prefix_len()),
            )
        } else {
            LocalEndpoint::Responder(
                &self.responder,
                IpNet::new_assert(tunnel_ip_range.next().unwrap(), self.cidr.prefix_len()),
            )
        }
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct GetTunnelsResponse {
    pub tunnels: Vec<Tunnel>,
}
