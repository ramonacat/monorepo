use std::{collections::HashMap, time::Duration};

use sqlx::{Postgres, Transaction};
use uuid::Uuid;

use crate::dns::{Record, Zone};

pub async fn upsert_record(
    tx: &mut Transaction<'_, Postgres>,
    zone_name: &str,
    name: &str,
    r#type: &str,
    rrdatas: &[String],
    ttl: Option<Duration>,
) -> anyhow::Result<()> {
    let zone_id: Uuid = sqlx::query!("SELECT id FROM dns_zone WHERE name=$1", zone_name)
        .fetch_one(&mut **tx)
        .await?
        .id;

    sqlx::query!("
            INSERT INTO dns_record (id, zone_id, name, type, rrdatas, ttl)
            VALUES(uuidv7(), $1, $2, $3, $4, $5)
            ON CONFLICT(zone_id, name) DO UPDATE SET type=EXCLUDED.type, rrdatas=EXCLUDED.rrdatas, ttl=EXCLUDED.ttl
        ", zone_id, name, r#type, rrdatas, ttl.map(|x| x.as_secs() as i32)).execute(&mut **tx).await?;

    sqlx::query!("UPDATE dns_zone SET serial=serial+1 WHERE id=$1", zone_id)
        .execute(&mut **tx)
        .await?;

    Ok(())
}

pub async fn delete_record(
    tx: &mut Transaction<'_, Postgres>,
    zone_name: &str,
    name: &str,
    r#type: Option<&str>,
) -> anyhow::Result<()> {
    let zone_id: Uuid = sqlx::query!("SELECT id FROM dns_zone WHERE name=$1", zone_name)
        .fetch_one(&mut **tx)
        .await?
        .id;

    sqlx::query!(
        "
        DELETE FROM dns_record
        WHERE zone_id=$1
            AND name=$2
            AND ($3::text IS NULL OR \"type\"=$3)
    ",
        zone_id,
        name,
        r#type
    )
    .execute(&mut **tx)
    .await?;
    sqlx::query!("UPDATE dns_zone SET serial=serial+1 WHERE id=$1", zone_id)
        .execute(&mut **tx)
        .await?;

    Ok(())
}

pub async fn get_all_zones(tx: &mut Transaction<'_, Postgres>) -> anyhow::Result<Vec<Zone>> {
    let zones = sqlx::query!("SELECT * FROM dns_zone")
        .fetch_all(&mut **tx)
        .await?;
    let records = sqlx::query!("SELECT * FROM dns_record")
        .fetch_all(&mut **tx)
        .await?;

    let mut records_by_zone = HashMap::new();
    for record in records {
        records_by_zone
            .entry(record.zone_id)
            .or_insert_with(Vec::new)
            .push(Record {
                id: record.id,
                name: record.name,
                r#type: record.r#type,
                rrdatas: record.rrdatas,
                ttl: record.ttl.map(|ttl| Duration::from_secs(ttl as u64)),
            });
    }

    Ok(zones
        .into_iter()
        .map(|zone| Zone {
            id: zone.id,
            name: zone.name,
            serial: zone.serial.try_into().unwrap(),
            refresh: Duration::from_secs(zone.refresh as u64),
            retry: Duration::from_secs(zone.retry as u64),
            expire: Duration::from_secs(zone.expire as u64),
            negative_response_ttl: Duration::from_secs(zone.negative_response_ttl as u64),
            default_ttl: Duration::from_secs(zone.default_ttl as u64),
            records: records_by_zone.remove(&zone.id).unwrap_or_default(),
        })
        .collect())
}
