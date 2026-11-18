use ipnet::IpNet;
use rlib::hosts::{HostStateV2, Hostname};
use sqlx::{Postgres, Transaction};

pub async fn update_group(
    tx: &mut Transaction<'_, Postgres>,
    hostname: &Hostname,
    group_name: Option<&str>,
) -> anyhow::Result<()> {
    sqlx::query!(
        "UPDATE host SET host_group_id=(SELECT id FROM host_group WHERE name=$1) WHERE name=$2",
        group_name,
        hostname.first_label()
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
