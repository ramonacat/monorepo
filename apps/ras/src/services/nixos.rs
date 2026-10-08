use rlib::hosts::Hostname;
use sqlx::{Postgres, Transaction};
use uuid::Uuid;

pub struct ClosureName(String);

impl ClosureName {
    pub fn from_host(name: &Hostname) -> Self {
        Self(format!("host:{}", name.first_label()))
    }

    pub fn from_home(name: &str) -> Self {
        Self(format!("home:{}", name))
    }
}

#[derive(Debug)]
pub struct StorePath(String);

impl StorePath {
    pub fn new(value: String) -> Self {
        Self(value)
    }

    pub fn raw(&self) -> &str {
        &self.0
    }
}

pub async fn get_latest_closure<'tx>(
    tx: &mut Transaction<'tx, Postgres>,
    name: ClosureName,
) -> Result<StorePath, sqlx::Error> {
    sqlx::query_scalar!(
        "SELECT latest_store_path FROM nixos_closure WHERE name=$1",
        name.0
    )
    .fetch_one(&mut **tx)
    .await
    .map(StorePath::new)
}

pub async fn update_latest_closure<'tx>(
    tx: &mut Transaction<'tx, Postgres>,
    name: ClosureName,
    store_path: StorePath,
) -> Result<(), sqlx::Error> {
    sqlx::query!("
        INSERT INTO nixos_closure (id,name,latest_store_path,updated_at)
            VALUES (uuidv7(), $1, $2, CURRENT_TIMESTAMP)
            ON CONFLICT (name)
                DO UPDATE SET latest_store_path=EXCLUDED.latest_store_path, updated_at=EXCLUDED.updated_at
    ", name.0, store_path.0).execute(&mut **tx).await?;

    Ok(())
}

pub async fn update_current_host_closure<'tx>(
    tx: &mut Transaction<'tx, Postgres>,
    hostname: &Hostname,
    store_path: StorePath,
) -> Result<(), sqlx::Error> {
    let closure_state_id = sqlx::query_scalar!(
        "SELECT nixos_closure_state_id FROM host WHERE name=$1",
        hostname.first_label()
    )
    .fetch_one(&mut **tx)
    .await?;

    if let Some(closure_state_id) = closure_state_id {
        sqlx::query!("UPDATE nixos_closure_state SET current_store_path=$1, updated_at=CURRENT_TIMESTAMP WHERE id=$2", store_path.0, closure_state_id).execute(&mut **tx).await?;
    } else {
        let closure_id = sqlx::query_scalar!(
            "SELECT id FROM nixos_closure WHERE name=$1",
            ClosureName::from_host(&hostname).0
        )
        .fetch_one(&mut **tx)
        .await?;
        let id = Uuid::now_v7();
        sqlx::query!(
            "
            INSERT INTO nixos_closure_state (id, closure_id, current_store_path, updated_at)
                VALUES ($1, $2, $3, CURRENT_TIMESTAMP)
        ",
            id,
            closure_id,
            store_path.0
        )
        .execute(&mut **tx)
        .await?;

        sqlx::query!(
            "UPDATE host SET nixos_closure_state_id=$1 WHERE name=$2",
            id,
            hostname.first_label()
        )
        .execute(&mut **tx)
        .await?;
    }

    Ok(())
}

pub async fn update_current_home_closure<'tx>(
    tx: &mut Transaction<'tx, Postgres>,
    closure_name: &ClosureName,
    hostname: &Hostname,
    store_path: StorePath,
) -> Result<(), sqlx::Error> {
    let closure_id =
        sqlx::query_scalar!("SELECT id FROM nixos_closure WHERE name=$1", closure_name.0)
            .fetch_one(&mut **tx)
            .await
            .unwrap();
    let closure_state_id = sqlx::query_scalar!(
        "SELECT h.nixos_closure_state_id FROM home h WHERE h.hostname=$1",
        hostname.first_label()
    )
    .fetch_one(&mut **tx)
    .await
    .unwrap();

    if let Some(closure_state_id) = closure_state_id {
        sqlx::query!("UPDATE nixos_closure_state SET current_store_path=$1, updated_at=CURRENT_TIMESTAMP WHERE id=$2", store_path.raw() , closure_state_id).execute(&mut **tx).await.unwrap();
    } else {
        let id = Uuid::now_v7();

        sqlx::query!("
            INSERT INTO 
                nixos_closure_state(id, closure_id, current_store_path, updated_at) VALUES($1, $2, $3, CURRENT_TIMESTAMP)", id, closure_id, store_path.raw()).execute(&mut **tx).await.unwrap();

        sqlx::query!(
            "UPDATE home SET nixos_closure_state_id=$1 WHERE hostname=$2",
            id,
            &hostname.first_label()
        )
        .execute(&mut **tx)
        .await
        .unwrap();
    };

    Ok(())
}
