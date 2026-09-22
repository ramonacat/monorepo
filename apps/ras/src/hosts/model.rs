use std::{collections::HashSet, net::SocketAddr};

use chrono::{DateTime, Utc};
use ipnet::IpNet;
use rlib::hosts::HostAddress;
use thiserror::Error;

use diesel::{
    ExpressionMethods, OptionalEmptyChangesetExtension, OptionalExtension as _, QueryDsl as _,
    delete, insert_into,
    query_builder::AsChangeset,
    sql_query,
    sql_types::{Inet, Text},
    update,
    upsert::excluded,
};
use diesel_async::{AsyncConnection, AsyncPgConnection, RunQueryDsl as _};

#[derive(Debug, Error)]
pub enum UpdateClosureError {
    #[error("diesel: {0}")]
    Diesel(#[from] diesel::result::Error),
}

#[derive(Debug, AsChangeset)]
#[diesel(table_name = crate::schema::host_closure_state)]
struct ClosureChangeset {
    current_closure: Option<String>,
    current_closure_updated_at: Option<DateTime<Utc>>,
    latest_closure: Option<String>,
    latest_closure_updated_at: Option<DateTime<Utc>>,
}

pub async fn update_closure(
    connection: &mut AsyncPgConnection,
    hostname: &str,
    current_closure: Option<String>,
    latest_closure: Option<String>,
) -> Result<(), UpdateClosureError> {
    connection
        .transaction(async |connection| {
            use crate::schema::host_closure_state::dsl;

            let current_state: Option<crate::models::HostClosureState> = dsl::host_closure_state
                .find(&hostname)
                .first(connection)
                .await
                .optional()?;
            let now = Utc::now();

            if let Some(current_state) = current_state {
                let mut changeset = ClosureChangeset {
                    current_closure: None,
                    current_closure_updated_at: None,
                    latest_closure: None,
                    latest_closure_updated_at: None,
                };

                if current_state.current_closure != current_closure && current_closure.is_some() {
                    changeset.current_closure = current_closure;
                    changeset.current_closure_updated_at = Some(now);
                }

                if current_state.latest_closure != latest_closure && latest_closure.is_some() {
                    changeset.latest_closure = latest_closure;
                    changeset.latest_closure_updated_at = Some(now);
                }

                update(dsl::host_closure_state)
                    .set(changeset)
                    .filter(dsl::hostname.eq(hostname))
                    .execute(connection)
                    .await
                    .optional_empty_changeset()?;
            } else {
                insert_into(dsl::host_closure_state)
                    .values((
                        dsl::hostname.eq(hostname),
                        dsl::current_closure_updated_at.eq(current_closure.as_ref().map(|_| now)),
                        dsl::current_closure.eq(current_closure),
                        dsl::latest_closure_updated_at.eq(latest_closure.as_ref().map(|_| now)),
                        dsl::latest_closure.eq(latest_closure),
                    ))
                    .execute(connection)
                    .await?;
            }

            Ok(())
        })
        .await
}

#[derive(Debug, Error)]
pub enum UpdateAddressesError {
    #[error("diesel: {0}")]
    Diesel(#[from] diesel::result::Error),
}

pub async fn update_addresses(
    connection: &mut AsyncPgConnection,
    hostname: &str,
    addresses: HashSet<HostAddress>,
) -> Result<(), UpdateAddressesError> {
    connection
        .transaction(async |connection| {
            sql_query("CREATE TEMPORARY TABLE new_addresses(
                address INET NOT NULL,
                hostname TEXT NOT NULL,
                interface TEXT NOT NULL
            ) ON COMMIT DROP").execute(connection).await.unwrap();

            for address in &addresses {
                sql_query(r###"INSERT INTO new_addresses("address", "hostname", "interface") VALUES($1, $2, $3)"###)
                    .bind::<Inet, _>(address.address)
                    .bind::<Text, _>(hostname)
                    .bind::<Text, _>(&address.interface)
                    .execute(connection).await.unwrap();
            }

            sql_query("
                MERGE INTO host_ip_address AS tgt
                    USING new_addresses AS src ON tgt.hostname = src.hostname AND tgt.interface = src.interface AND tgt.address = src.address
                    WHEN MATCHED THEN DO NOTHING
                    WHEN NOT MATCHED BY SOURCE AND hostname = $1 THEN DELETE
                    WHEN NOT MATCHED BY TARGET AND hostname = $1 THEN INSERT (id,hostname,interface,address) VALUES (uuidv7(),src.hostname,src.interface,src.address)
            ")
                .bind::<Text, _>(hostname)
                .execute(connection).await.unwrap();

            Ok(())
        })
        .await
}

#[derive(Debug, Error)]
pub enum UpdateWireguardEndpointError {
    #[error("diesel: {0}")]
    Diesel(#[from] diesel::result::Error),
}

pub async fn update_wireguard_endpoint(
    connection: &mut AsyncPgConnection,
    hostname: String,
    public_key: &str,
    endpoint: Option<&SocketAddr>,
) -> Result<(), UpdateWireguardEndpointError> {
    use crate::schema::wireguard_endpoint::dsl;

    insert_into(dsl::wireguard_endpoint)
        .values((
            dsl::hostname.eq(hostname),
            dsl::endpoint.eq(endpoint.as_ref().map(|x| IpNet::from((x).ip()))),
            dsl::port.eq(endpoint.as_ref().map(|x| x.port() as i32)),
            dsl::public_key.eq(public_key),
        ))
        .on_conflict(dsl::hostname)
        .do_update()
        .set((
            dsl::endpoint.eq(excluded(dsl::endpoint)),
            dsl::port.eq(excluded(dsl::port)),
            dsl::public_key.eq(excluded(dsl::public_key)),
        ))
        .execute(connection)
        .await?;

    Ok(())
}

#[derive(Debug, Error)]
pub enum DeleteWireguardEndpointError {
    #[error("diesel: {0}")]
    Diesel(#[from] diesel::result::Error),
}

pub async fn delete_wireguard_endpoint(
    connection: &mut AsyncPgConnection,
    hostname: &str,
) -> Result<(), DeleteWireguardEndpointError> {
    use crate::schema::wireguard_endpoint::dsl;

    delete(dsl::wireguard_endpoint)
        .filter(dsl::hostname.eq(hostname))
        .execute(connection)
        .await?;

    Ok(())
}
