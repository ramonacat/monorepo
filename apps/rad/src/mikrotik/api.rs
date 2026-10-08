use std::net::IpAddr;

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
    pub listen_port: u16,
    pub public_key: String,
}

#[derive(Debug)]
pub struct InterfaceWireguardPeer {
    pub id: String,
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
            .send("/interace/wireguard/print", [], query)
            .await?
            .into_iter()
            .filter_map(|x| match x {
                super::ResponseLine::Done | super::ResponseLine::Empty => None,
                super::ResponseLine::Data(hash_map) => Some(InterfaceWireguard {
                    id: hash_map.get("*id").unwrap().clone(),
                    listen_port: hash_map.get("listen-port").unwrap().parse().unwrap(),
                    public_key: hash_map.get("public-key").unwrap().clone(),
                }),
            });

        Ok(interfaces.collect())
    }

    pub async fn interface_wireguard_set(
        &mut self,
        id: &str,
        listen_port: u16,
        key: &crate::host::networking::wireguard::Key,
    ) -> anyhow::Result<()> {
        self.connection
            .send(
                "/interface/wireguard/set",
                [
                    (".id", id),
                    ("listen-port", &listen_port.to_string()),
                    ("private-key", &key.to_private_base64()),
                ],
                [],
            )
            .await?;

        Ok(())
    }

    pub async fn interface_wireguard_add(
        &mut self,
        name: &str,
        listen_port: u16,
        key: &crate::host::networking::wireguard::Key,
    ) -> anyhow::Result<()> {
        self.connection
            .send(
                "/interface/wireguard/add",
                [
                    ("name", name),
                    ("listen-port", &listen_port.to_string()),
                    ("private-key", &key.to_private_base64()),
                ],
                [],
            )
            .await?;

        Ok(())
    }

    pub async fn interface_wireguard_peers_find<'a>(
        &mut self,
        query: impl IntoIterator<Item = &'a str>,
    ) -> anyhow::Result<Vec<InterfaceWireguardPeer>> {
        let peers = self
            .connection
            .send("/interace/wireguard/peers/print", [], query)
            .await?
            .into_iter()
            .filter_map(|x| match x {
                super::ResponseLine::Done | super::ResponseLine::Empty => None,
                super::ResponseLine::Data(hash_map) => Some(InterfaceWireguardPeer {
                    id: hash_map.get("*id").unwrap().clone(),
                    public_key: hash_map.get("public-key").unwrap().clone(),
                    endpoint_address: hash_map.get("endpoint-address").unwrap().clone(),
                }),
            });

        Ok(peers.collect())
    }

    pub async fn interface_wireguard_peers_set(
        &mut self,
        id: &str,
        public_key: &str,
        endpoint_address: IpAddr,
        endpoint_port: u16,
        allowed_addresses: &str,
        persistent_keepalive: &str,
    ) -> anyhow::Result<()> {
        self.connection
            .send(
                "/interface/wireguard/peers/set",
                [
                    (".id", id),
                    ("public-key", public_key),
                    ("endpoint-address", &endpoint_address.to_string()),
                    ("endpoint-port", &endpoint_port.to_string()),
                    ("allowed-address", allowed_addresses),
                    ("persistent-keepalive", persistent_keepalive),
                ],
                [],
            )
            .await?;

        Ok(())
    }

    pub async fn interface_wireguard_peers_add(
        &mut self,
        interface: &str,
        public_key: &str,
        endpoint_address: IpAddr,
        endpoint_port: u16,
        allowed_addresses: &str,
        persistent_keepalive: &str,
    ) -> anyhow::Result<()> {
        self.connection
            .send(
                "/interface/wireguard/peers/add",
                [
                    ("interface", interface),
                    ("public-key", public_key),
                    ("endpoint-address", &endpoint_address.to_string()),
                    ("endpoint-port", &endpoint_port.to_string()),
                    ("allowed-address", allowed_addresses),
                    ("persistent-keepalive", persistent_keepalive),
                ],
                [],
            )
            .await?;

        Ok(())
    }

    pub async fn ip_address_find<'a>(
        &mut self,
        query: impl IntoIterator<Item = &'a str>,
    ) -> anyhow::Result<Vec<IpAddress>> {
        let addresses = self
            .connection
            .send("/ip/address/print", [], query)
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
}
