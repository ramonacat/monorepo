use ipnet::IpNet;
use rlib::hosts::{HostStateV2, Hostname};
use sqlx::{Postgres, Transaction};

pub async fn update_groups(
    tx: &mut Transaction<'_, Postgres>,
    hostname: &Hostname,
    group_names: &[String],
) -> anyhow::Result<()> {
    let host_id = sqlx::query_scalar!("SELECT id FROM host WHERE name=$1", hostname.first_label())
        .fetch_one(&mut **tx)
        .await?;

    sqlx::query!(
        "DELETE FROM host_to_host_group 
        WHERE host_id=$1 
            AND host_group_id NOT IN (
                SELECT id FROM host_group WHERE name IN (
                    SELECT * FROM unnest($2::text[])
                )
            )",
        host_id,
        group_names
    )
    .execute(&mut **tx)
    .await?;

    sqlx::query!(
        "INSERT INTO host_to_host_group (host_id, host_group_id) 
        SELECT $1, id FROM host_group 
        WHERE name IN (SELECT * FROM unnest($2::text[]))",
        host_id,
        group_names
    )
    .execute(&mut **tx)
    .await?;

    Ok(())
}

pub async fn update_main_ip(
    tx: &mut Transaction<'_, Postgres>,
    hostname: &Hostname,
    ip: IpNet,
) -> Result<(), sqlx::Error> {
    sqlx::query!(
        "UPDATE host SET main_ip=$1 WHERE name=$2",
        ip,
        hostname.first_label()
    )
    .execute(&mut **tx)
    .await?;

    Ok(())
}

pub async fn get_state_v2(
    tx: &mut Transaction<'_, Postgres>,
    hostname: Hostname,
) -> anyhow::Result<HostStateV2> {
    let result = sqlx::query!(
        "SELECT id, main_ip, zone, region FROM host WHERE name = $1",
        hostname.first_label()
    )
    .fetch_one(&mut **tx)
    .await?;

    let ip = if let Some(ip) = result.main_ip {
        ip
    } else {
        let ips = sqlx::query_scalar!(
            "SELECT address FROM ipam_live_ip WHERE host_id=$1",
            result.id
        )
        .fetch_all(&mut **tx)
        .await?;

        *ips.iter()
            .find(|x| match x {
                ipnet::IpNet::V4(ipv4_net) => ipv4_net.addr().is_private(),
                ipnet::IpNet::V6(_) => false,
            })
            .unwrap()
    };

    Ok(HostStateV2 {
        id: result.id,
        main_ip: ip.addr(),
        zone: result.zone,
        region: result.region,
    })
}

pub async fn ensure_host(
    tx: &mut Transaction<'_, Postgres>,
    hostname: &Hostname,
) -> Result<(), sqlx::Error> {
    sqlx::query!(
        "INSERT INTO 
        host (id, name, nixos_closure_state_id, main_ip) 
        VALUES(uuidv7(),$1, NULL, NULL)
        ON CONFLICT DO NOTHING
        ",
        hostname.first_label()
    )
    .execute(&mut **tx)
    .await?;

    Ok(())
}
