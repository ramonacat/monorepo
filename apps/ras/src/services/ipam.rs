use ipnet::IpNet;
use rlib::hosts::{HostAddress, Hostname};
use sqlx::{Postgres, Transaction};
use thiserror::Error;
use tracing::info;
use uuid::Uuid;

struct AddressAllocation {
    id: Uuid,
    cidr: IpNet,
}

#[derive(Debug, Error)]
pub enum AllocateCidrError {
    #[error("no subnets of this size are available in the parent")]
    NoAvailableSubnets,

    #[error("sqlx: {0}")]
    Sqlx(#[from] sqlx::Error),

    #[error("invalid prefix length: {0}")]
    InvalidPrefixLength(#[from] ipnet::PrefixLenError),
}

pub const ALLOCATION_NAME_WIREGUARD_TUNNELS: &str = "tunnels";

pub async fn get_allocation_id(
    tx: &mut Transaction<'_, Postgres>,
    name: &str,
) -> Result<Uuid, sqlx::Error> {
    sqlx::query_scalar!("SELECT id FROM ipam_address_allocation WHERE name=$1", name)
        .fetch_one(&mut **tx)
        .await
}

pub async fn allocate_cidr<'tx>(
    tx: &mut Transaction<'tx, Postgres>,
    parent_id: Uuid,
    name: String,
    width: u8,
) -> Result<Uuid, AllocateCidrError> {
    let parent = get_allocation(tx, parent_id).await?;
    for candidate in parent.cidr.subnets(width)? {
        let in_use = sqlx::query_scalar!("SELECT EXISTS(SELECT 1 FROM ipam_address_allocation WHERE parent_id=$1 AND cidr && $2) AS \"exists!\"", parent.id, candidate).fetch_one(&mut **tx).await?;

        if in_use {
            continue;
        }

        let id = Uuid::now_v7();
        sqlx::query!(
            "INSERT INTO ipam_address_allocation(id,name,parent_id,cidr) VALUES($1, $2, $3, $4)",
            id,
            name,
            parent.id,
            candidate
        )
        .execute(&mut **tx)
        .await?;

        info!(cidr=?candidate, ?id, "allocated cidr");

        return Ok(id);
    }

    Err(AllocateCidrError::NoAvailableSubnets)
}

async fn get_allocation<'tx>(
    tx: &mut Transaction<'tx, Postgres>,
    id: Uuid,
) -> Result<AddressAllocation, sqlx::Error> {
    sqlx::query_as!(
        AddressAllocation,
        "SELECT id, cidr FROM ipam_address_allocation WHERE id=$1",
        id
    )
    .fetch_one(&mut **tx)
    .await
}

pub async fn update_live_ips<'tx>(
    tx: &mut Transaction<'tx, Postgres>,
    hostname: &Hostname,
    mut addresses: Vec<HostAddress>,
) -> Result<(), sqlx::Error> {
    let host_id = sqlx::query_scalar!(
        "SELECT id FROM host h WHERE h.name=$1",
        hostname.first_label()
    )
    .fetch_one(&mut **tx)
    .await?;
    let current_ips = sqlx::query!(
        "
        SELECT 
            ili.* 
        FROM ipam_live_ip ili
        WHERE ili.host_id=$1
        ",
        host_id
    )
    .fetch_all(&mut **tx)
    .await?;

    for current_ip in current_ips {
        let mut extracted = addresses.extract_if(.., |x| {
            x.address == current_ip.address && x.interface == current_ip.interface_name
        });

        if extracted.next().is_none() {
            sqlx::query!("DELETE FROM ipam_live_ip WHERE id=$1", current_ip.id)
                .execute(&mut **tx)
                .await?;
        }
    }

    for address in addresses {
        sqlx::query!(
            "
                INSERT INTO 
                    ipam_live_ip(id, host_id, address, interface_name, allocation_id) 
                VALUES(
                    uuidv7(),
                    $1,
                    $2,
                    $3,
                    NULL
                )
            ",
            host_id,
            address.address,
            address.interface
        )
        .execute(&mut **tx)
        .await?;
    }

    sqlx::query!("UPDATE ipam_live_ip AS ili SET allocation_id=(SELECT iaa.id FROM ipam_address_allocation iaa WHERE ili.address && iaa.cidr ORDER BY masklen(iaa.cidr) DESC LIMIT 1)").execute(&mut **tx).await?;

    Ok(())
}
