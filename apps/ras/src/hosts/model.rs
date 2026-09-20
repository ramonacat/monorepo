use std::collections::HashSet;

use chrono::{DateTime, Utc};
use ipnet::IpNet;
use rlib::hosts::UDPEndpoint;
use thiserror::Error;

use diesel::{
    BoolExpressionMethods, ExpressionMethods, OptionalEmptyChangesetExtension,
    OptionalExtension as _, QueryDsl as _, delete, insert_into, query_builder::AsChangeset, update,
    upsert::excluded,
};
use diesel_async::{AsyncConnection, AsyncPgConnection, RunQueryDsl as _};

use crate::models::HostIpAddress;

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
    addresses: Vec<IpNet>,
) -> Result<(), UpdateAddressesError> {
    connection
        .transaction(async |connection| {
            use crate::schema::host_ip_address::dsl;

            delete(dsl::host_ip_address)
                .filter(
                    dsl::hostname
                        .eq(&hostname)
                        .and(dsl::address.ne_all(&addresses)),
                )
                .execute(connection)
                .await
                .unwrap();

            let current_ips: HashSet<_> = dsl::host_ip_address
                .filter(dsl::hostname.eq(&hostname))
                .load(connection)
                .await?
                .into_iter()
                .map(|x: HostIpAddress| x.address)
                .collect();
            let records: Vec<_> = addresses
                .into_iter()
                .filter(|x| !current_ips.contains(x))
                .map(|x| (dsl::hostname.eq(&hostname), dsl::address.eq(x)))
                .collect();

            insert_into(dsl::host_ip_address)
                .values(records)
                .execute(connection)
                .await?;
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
    endpoint: Option<&UDPEndpoint>,
) -> Result<(), UpdateWireguardEndpointError> {
    use crate::schema::wireguard_endpoint::dsl;

    insert_into(dsl::wireguard_endpoint)
        .values((
            dsl::hostname.eq(hostname),
            dsl::endpoint.eq(endpoint.as_ref().map(|x| x.adddress())),
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
