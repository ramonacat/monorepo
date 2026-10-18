use std::{collections::HashMap, net::SocketAddr};

use ipnet::IpNet;
use rlib::hosts::Hostname;
use tokio::io::{AsyncRead, AsyncWrite};

use crate::mikrotik::Connection;

pub struct Api<T: Unpin + AsyncWrite + AsyncRead> {
    connection: Connection<T>,
}

pub struct SystemIdentity {
    pub name: Hostname,
}

#[derive(Debug)]
pub struct InterfaceWireguard {
    pub id: String,
    pub listen_port: Option<u16>,
    pub public_key: String,
}

#[derive(Debug)]
pub struct InterfaceWireguardPeer {
    pub id: String,
    pub name: String,
    pub public_key: String,
    pub endpoint_address: String,
}

#[derive(Debug)]
pub struct IpAddress {
    pub address: IpNet,
    pub interface: String,
}

impl<T: Unpin + AsyncWrite + AsyncRead> Api<T> {
    pub fn new(connection: Connection<T>) -> Self {
        Self { connection }
    }

    pub async fn system_identity_get(&mut self) -> anyhow::Result<SystemIdentity> {
        let hostname = self
            .connection
            .send("system/identity/print", [], [])
            .await?
            .into_iter()
            .filter_map(|x| match x {
                super::ResponseLine::Done | super::ResponseLine::Empty => None,
                super::ResponseLine::Data(hash_map) => Some(hash_map.get("name").unwrap().clone()),
            })
            .next()
            .unwrap();

        Ok(SystemIdentity {
            name: Hostname::new(hostname),
        })
    }

    pub async fn interface_wireguard_find<'a>(
        &mut self,
        query: impl IntoIterator<Item = &'a str>,
    ) -> anyhow::Result<Vec<InterfaceWireguard>> {
        let interfaces = self
            .connection
            .send("interface/wireguard/print", [], query)
            .await?
            .into_iter()
            .filter_map(|x| match x {
                super::ResponseLine::Done | super::ResponseLine::Empty => None,
                super::ResponseLine::Data(hash_map) => Some(InterfaceWireguard {
                    id: hash_map.get(".id").unwrap().clone(),
                    listen_port: hash_map.get("listen-port").map(|x| x.parse().unwrap()),
                    public_key: hash_map.get("public-key").unwrap().clone(),
                }),
            });

        Ok(interfaces.collect())
    }

    pub async fn interface_wireguard_set(
        &mut self,
        id: &str,
        listen_port: Option<u16>,
        key: &crate::host::networking::wireguard::Key,
    ) -> anyhow::Result<()> {
        let key = key.to_private_base64();
        let mut attributes =
            HashMap::from([(".id", id), ("private-key", &key), ("disabled", "false")]);
        let port;
        if let Some(listen_port) = listen_port {
            port = listen_port.to_string();
            attributes.insert("listen-port", &port);
        } else {
            attributes.insert("listen-port", "");
        }
        self.connection
            .send("interface/wireguard/set", attributes, [])
            .await?;

        Ok(())
    }

    pub async fn interface_wireguard_add(
        &mut self,
        name: &str,
        listen_port: Option<u16>,
        key: &crate::host::networking::wireguard::Key,
    ) -> anyhow::Result<()> {
        let key = key.to_private_base64();
        let mut attributes =
            HashMap::from([("name", name), ("private-key", &key), ("disabled", "false")]);

        let port;
        if let Some(listen_port) = listen_port {
            port = listen_port.to_string();
            attributes.insert("listen-port", &port);
        }

        self.connection
            .send("interface/wireguard/add", attributes, [])
            .await?;

        Ok(())
    }

    pub async fn interface_wireguard_peers_find<'a>(
        &mut self,
        query: impl IntoIterator<Item = &'a str>,
    ) -> anyhow::Result<Vec<InterfaceWireguardPeer>> {
        let peers = self
            .connection
            .send("interface/wireguard/peers/print", [], query)
            .await?
            .into_iter()
            .filter_map(|x| match x {
                super::ResponseLine::Done | super::ResponseLine::Empty => None,
                super::ResponseLine::Data(hash_map) => Some(InterfaceWireguardPeer {
                    id: hash_map.get(".id").unwrap().clone(),
                    name: hash_map.get("name").unwrap().clone(),
                    public_key: hash_map.get("public-key").unwrap().clone(),
                    endpoint_address: hash_map.get("endpoint-address").unwrap().clone(),
                }),
            });

        Ok(peers.collect())
    }

    pub async fn interface_wireguard_peers_set(
        &mut self,
        id: &str,
        name: &str,
        public_key: &str,
        endpoint: Option<SocketAddr>,
        allowed_addresses: &str,
        persistent_keepalive: &str,
    ) -> anyhow::Result<()> {
        let mut attributes = HashMap::from([
            (".id", id),
            ("public-key", public_key),
            ("name", name),
            ("allowed-address", allowed_addresses),
            ("persistent-keepalive", persistent_keepalive),
            ("disabled", "false"),
        ]);

        let (ip, port);
        if let Some(endpoint) = endpoint {
            ip = endpoint.ip().to_string();
            port = endpoint.port().to_string();

            attributes.insert("endpoint-address", &ip);
            attributes.insert("endpoint-port", &port);
        }

        self.connection
            .send("interface/wireguard/peers/set", attributes, [])
            .await?;

        Ok(())
    }

    pub async fn interface_wireguard_peers_add(
        &mut self,
        name: &str,
        interface: &str,
        public_key: &str,
        endpoint: Option<SocketAddr>,
        allowed_addresses: &str,
        persistent_keepalive: &str,
    ) -> anyhow::Result<()> {
        let mut attributes = HashMap::from([
            ("name", name),
            ("interface", interface),
            ("public-key", public_key),
            ("allowed-address", allowed_addresses),
            ("persistent-keepalive", persistent_keepalive),
            ("disabled", "false"),
        ]);

        let (ip, port);
        if let Some(endpoint) = endpoint {
            ip = endpoint.ip().to_string();
            port = endpoint.port().to_string();

            attributes.insert("endpoint-address", &ip);
            attributes.insert("endpoint-port", &port);
        }

        self.connection
            .send("interface/wireguard/peers/add", attributes, [])
            .await?;

        Ok(())
    }

    pub async fn ip_address_find<'a>(
        &mut self,
        query: impl IntoIterator<Item = &'a str>,
    ) -> anyhow::Result<Vec<IpAddress>> {
        let addresses = self
            .connection
            .send("ip/address/print", [], query)
            .await?
            .into_iter()
            .filter_map(|x| match x {
                super::ResponseLine::Done | super::ResponseLine::Empty => None,
                super::ResponseLine::Data(hash_map) => Some(IpAddress {
                    address: hash_map.get("address").unwrap().parse().unwrap(),
                    interface: hash_map.get("interface").unwrap().clone(),
                }),
            });

        Ok(addresses.collect())
    }

    pub async fn ip_address_add(
        &mut self,
        address: IpNet,
        interface: &str,
    ) -> anyhow::Result<String> {
        let address = address.to_string();
        self.connection
            .send(
                "ip/address/add",
                [
                    ("address", address.as_str()),
                    ("interface", interface),
                    ("disabled", "false"),
                ],
                [],
            )
            .await?;

        let query_interface = format!("interface={interface}");
        let query_address = format!("address={address}");
        let response = self
            .connection
            .send(
                "ip/address/print",
                [],
                [query_interface.as_str(), &query_address],
            )
            .await?;

        Ok(response
            .iter()
            .filter_map(|x| match x {
                super::ResponseLine::Done | super::ResponseLine::Empty => None,
                super::ResponseLine::Data(data) => Some(data.get(".id").unwrap().clone()),
            })
            .next()
            .unwrap())
    }

    pub async fn ip_address_set(
        &mut self,
        id: &str,
        address: IpNet,
        interface: &str,
    ) -> anyhow::Result<()> {
        let address = address.to_string();
        self.connection
            .send(
                "ip/address/set",
                [
                    (".id", id),
                    ("address", address.as_str()),
                    ("interface", interface),
                    ("disabled", "false"),
                ],
                [],
            )
            .await?;

        Ok(())
    }
}
