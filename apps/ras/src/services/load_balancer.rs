use std::net::IpAddr;

use rlib::load_balancers::ServicePort;
use sqlx::{Postgres, Transaction};
use uuid::Uuid;

use crate::services::ipam::{allocate_cidr, get_allocation_id};

pub async fn upsert_load_balancer(
    tx: &mut Transaction<'_, Postgres>,
    id: Uuid,
    host_group_id: Uuid,
    ports: &[ServicePort],
) -> anyhow::Result<IpAddr> {
    let ports = serde_json::to_value(ports)?;

    let current_balancer = sqlx::query!("SELECT * FROM load_balancer WHERE id=$1", id)
        .fetch_optional(&mut **tx)
        .await?;

    if let Some(current_balancer) = current_balancer {
        if current_balancer.host_group_id != host_group_id || current_balancer.ports != ports {
            sqlx::query!(
                "UPDATE load_balancer SET host_group_id=$1, ports=$2 WHERE id=$3",
                host_group_id,
                ports,
                id
            )
            .execute(&mut **tx)
            .await?;
        }

        let allocated_cidr = sqlx::query!(
            "SELECT cidr FROM ipam_address_allocation WHERE id=$1",
            current_balancer.address_allocation_id
        )
        .fetch_one(&mut **tx)
        .await?;

        return Ok(allocated_cidr.cidr.addr());
    }

    let parent_allocation_name = format!("load balancers/{host_group_id}");
    let parent_allocation_id = match get_allocation_id(tx, &parent_allocation_name).await? {
        Some(x) => x,
        None => {
            let load_balancers_allocation_id =
                get_allocation_id(tx, "load balancers").await?.unwrap();
            allocate_cidr(tx, load_balancers_allocation_id, parent_allocation_name, 24)
                .await?
                .0
        }
    };

    let (address_allocation_id, cidr) = allocate_cidr(
        tx,
        parent_allocation_id,
        format!("load balancers/{host_group_id}/{id}"),
        32,
    )
    .await?;
    sqlx::query!(
        "
        INSERT INTO load_balancer(id, host_group_id, ports, address_allocation_id)
        VALUES ($1, $2, $3, $4)
    ",
        id,
        host_group_id,
        ports,
        address_allocation_id
    )
    .execute(&mut **tx)
    .await?;

    Ok(cidr.addr())
}
