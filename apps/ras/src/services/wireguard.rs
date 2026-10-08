use std::{
    collections::{HashMap, HashSet},
    hash::Hash,
    net::IpAddr,
};

use ipnet::IpNet;
use rlib::hosts::{Hostname, WireguardState};
use sqlx::{Postgres, Transaction};
use tracing::{debug, info, warn};
use uuid::Uuid;

use crate::services::ipam::{ALLOCATION_NAME_WIREGUARD_TUNNELS, allocate_cidr, get_allocation_id};

pub async fn update_wireguard(
    tx: &mut Transaction<'_, Postgres>,
    hostname: &Hostname,
    state: Option<WireguardState>,
) -> anyhow::Result<()> {
    match state {
        Some(state) => {
            let ports: Vec<_> = state.available_ports.into_iter().map(i32::from).collect();
            let addresses: Vec<_> = state
                .listen_addresses
                .into_iter()
                .map(|x| x.into())
                .collect();

            sqlx::query!(
                "
                    INSERT INTO wireguard_host (host_id, ports, addresses, public_key) 
                    VALUES ((SELECT id FROM host where name=$1), $2, $3, $4)
                    ON CONFLICT (host_id)
                        DO UPDATE SET ports=EXCLUDED.ports, addresses=EXCLUDED.addresses
                ",
                hostname.first_label(),
                &ports,
                &addresses,
                state.public_key
            )
            .execute(&mut **tx)
            .await?;
        }
        None => {
            sqlx::query!(
                "DELETE FROM wireguard_host WHERE host_id=(SELECT id FROM host WHERE name=$1)",
                hostname.first_label()
            )
            .execute(&mut **tx)
            .await?;
        }
    }

    reconcile_tunnels(tx).await?;

    Ok(())
}

struct UnorderedPair<T>(T, T);

impl<T: PartialOrd> UnorderedPair<T> {
    fn first(&self) -> &T {
        if self.0 < self.1 { &self.0 } else { &self.1 }
    }

    fn second(&self) -> &T {
        if self.0 < self.1 { &self.1 } else { &self.0 }
    }

    fn into_values(self) -> (T, T) {
        if self.0 < self.1 {
            (self.0, self.1)
        } else {
            (self.1, self.0)
        }
    }
}

impl<T: Hash + PartialOrd> Hash for UnorderedPair<T> {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        self.first().hash(state);
        self.second().hash(state);
    }
}

impl<T: PartialOrd + PartialEq> PartialEq for UnorderedPair<T> {
    fn eq(&self, other: &Self) -> bool {
        self.first() == other.first() && self.second() == other.second()
    }
}

impl<T: Ord + Eq> Eq for UnorderedPair<T> {}

async fn reconcile_tunnels<'tx>(tx: &mut Transaction<'tx, Postgres>) -> anyhow::Result<()> {
    let candidates: HashSet<_> = sqlx::query!(
        "
        SELECT 
            whl.host_id as left_id, 
            whr.host_id as right_id
        FROM wireguard_host whl
        CROSS JOIN wireguard_host whr
        WHERE whl.host_id != whr.host_id
    "
    )
    .fetch_all(&mut **tx)
    .await?
    .into_iter()
    .map(|x| UnorderedPair(x.left_id, x.right_id))
    .collect();

    let mut sorted_candidates: Vec<_> = candidates.into_iter().map(|x| x.into_values()).collect();
    sorted_candidates.sort();

    let mut current_tunnels: HashMap<_, _> = sqlx::query!("SELECT * FROM wireguard_tunnel")
        .fetch_all(&mut **tx)
        .await?
        .into_iter()
        .map(|x| (UnorderedPair(x.initiator_id, x.responder_id), x))
        .collect();

    let cidr_parent_id = get_allocation_id(tx, ALLOCATION_NAME_WIREGUARD_TUNNELS).await?;

    for (host_id_a, host_id_b) in sorted_candidates {
        if current_tunnels
            .remove(&UnorderedPair(host_id_a, host_id_b))
            .is_some()
        {
            debug!(?host_id_b, ?host_id_b, "tunnel already exists");

            continue;
        }

        let host_a = load_host(tx, host_id_a).await?;
        let host_b = load_host(tx, host_id_b).await?;

        let (responder, initiator) =
            match (host_a.addresses.is_empty(), host_b.addresses.is_empty()) {
                (true, true) => {
                    warn!(?host_a, ?host_b, "no globally routable ip found");

                    continue;
                }
                (false, false) => {
                    if host_a.ports.len() > host_b.ports.len() {
                        (host_a, host_b)
                    } else {
                        (host_b, host_a)
                    }
                }
                (true, false) => (host_a, host_b),
                (false, true) => (host_b, host_a),
            };

        let Some(responder_port) = responder.ports.first() else {
            warn!(?responder, ?initiator, "no free ports");

            continue;
        };

        info!(?responder, ?initiator, ?responder_port, "creating tunnel");
        let cidr_id = allocate_cidr(
            tx,
            cidr_parent_id,
            format!("tunnel: {} <-> {}", initiator.name, responder.name),
            31,
        )
        .await?;

        sqlx::query!("INSERT INTO wireguard_tunnel(id, initiator_id, responder_id, responder_port, ipam_address_allocation_id) VALUES(uuidv7(), $1, $2, $3, $4)", initiator.id, responder.id, responder_port, cidr_id).execute(&mut **tx).await?;
    }

    for (_, tunnel) in current_tunnels {
        info!(?tunnel, "removing tunnel");

        sqlx::query!("DELETE FROM wireguard_tunnel WHERE id=$1", tunnel.id)
            .execute(&mut **tx)
            .await?;
    }

    Ok(())
}

#[derive(Debug)]
struct WireguardHost {
    id: Uuid,
    name: String,
    addresses: Vec<IpNet>,
    ports: Vec<i32>,
}

async fn load_host(
    tx: &mut Transaction<'_, Postgres>,
    id: Uuid,
) -> Result<WireguardHost, sqlx::Error> {
    sqlx::query_as!(WireguardHost, "
        SELECT 
            h.id,
            h.name,
            wh.addresses,
            COALESCE((
                SELECT array_agg(port)
                FROM unnest(wh.ports) port
                WHERE NOT EXISTS (SELECT 1 FROM wireguard_tunnel WHERE responder_id=h.id AND responder_port=port)
            ), '{}') AS \"ports!\"
        FROM host h
        INNER JOIN wireguard_host wh ON wh.host_id=h.id
        WHERE h.id=$1
    ", id).fetch_one(&mut **tx).await
}

pub struct TunnelHost {
    pub id: Uuid,
    pub name: String,
    pub public_key: String,
}

pub struct Tunnel {
    pub id: Uuid,

    pub initiator: TunnelHost,
    pub responder: TunnelHost,

    pub cidr: IpNet,
    pub responder_port: u16,
    pub responder_ips: Vec<IpAddr>,
}

pub async fn get_tunnels_for_host(
    tx: &mut Transaction<'_, Postgres>,
    hostname: &Hostname,
) -> Result<Vec<Tunnel>, sqlx::Error> {
    let rows = sqlx::query!(
        "
            SELECT
                wt.id,
                i.id AS initiator_id,
                i.name AS initiator_name,
                iwh.public_key AS initiator_public_key,
                r.id AS responder_id,
                r.name AS responder_name,
                rwh.public_key AS responder_public_key,
                wt.responder_port,
                iaa.cidr,
                rwh.addresses AS responder_ips
            FROM wireguard_tunnel wt
            INNER JOIN host i ON i.id=wt.initiator_id
            INNER JOIN host r ON r.id=wt.responder_id
            INNER JOIN wireguard_host iwh ON i.id=iwh.host_id
            INNER JOIN wireguard_host rwh ON r.id=rwh.host_id
            INNER JOIN ipam_address_allocation iaa ON wt.ipam_address_allocation_id=iaa.id
            WHERE $1 IN (i.name, r.name)
        ",
        hostname.first_label()
    )
    .fetch_all(&mut **tx)
    .await?;

    Ok(rows
        .into_iter()
        .map(|x| Tunnel {
            id: x.id,
            initiator: TunnelHost {
                id: x.initiator_id,
                name: x.initiator_name,
                public_key: x.initiator_public_key,
            },
            responder: TunnelHost {
                id: x.responder_id,
                name: x.responder_name,
                public_key: x.responder_public_key,
            },
            cidr: x.cidr,
            responder_port: x.responder_port.try_into().unwrap(),
            responder_ips: x.responder_ips.into_iter().map(|x| x.addr()).collect(),
        })
        .collect())
}
