use std::convert::Into;

use rlib::{hosts::Hostname, routing::Route};
use sqlx::{Postgres, Transaction};
use uuid::Uuid;

pub async fn get_routes(tx: &mut Transaction<'_, Postgres>) -> Result<Vec<Route>, sqlx::Error> {
    let routes = sqlx::query!(
        "
        SELECT 
            rr.id, 
            rr.target_ips,
            rr.target_cidr,
            rr.blackhole,
            h.name AS hostname 
        FROM routing_route rr 
        INNER JOIN host h ON h.id=rr.target_host_id
    "
    )
    .fetch_all(&mut **tx)
    .await?;

    Ok(routes
        .into_iter()
        .map(|x| Route {
            id: x.id,
            target_hostname: Hostname::new(x.hostname),
            target_ips: x.target_ips.into_iter().map(|x| x.addr()).collect(),
            target_cidr: x.target_cidr,
            blackhole: x.blackhole,
        })
        .collect())
}

pub async fn create_route(
    tx: &mut Transaction<'_, Postgres>,
    route: Route,
) -> Result<(), sqlx::Error> {
    let target_ips: Vec<_> = route.target_ips.into_iter().map(Into::into).collect();
    sqlx::query!("INSERT INTO routing_route (id, target_host_id, target_ips, target_cidr, blackhole) VALUES (
        $1,
        (SELECT id FROM host WHERE name=$2),
        $3, $4, $5
    )", route.id, route.target_hostname.first_label(), &target_ips, route.target_cidr, route.blackhole).execute(&mut **tx).await?;

    Ok(())
}

pub async fn delete_route(tx: &mut Transaction<'_, Postgres>, id: Uuid) -> Result<(), sqlx::Error> {
    sqlx::query!("DELETE FROM routing_route WHERE id=$1", id)
        .execute(&mut **tx)
        .await?;

    Ok(())
}
