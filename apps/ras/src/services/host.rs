use rlib::hosts::Hostname;
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
