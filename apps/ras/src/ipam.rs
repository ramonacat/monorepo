use diesel::BoolExpressionMethods;
use diesel::dsl::insert_into;
use diesel::{
    ExpressionMethods, OptionalExtension, PgNetExpressionMethods, query_dsl::methods::FilterDsl,
};
use diesel_async::{AsyncPgConnection, RunQueryDsl};
use thiserror::Error;
use uuid::Uuid;

use crate::models::AddressAllocation;

#[derive(Debug, Error)]
pub enum AllocateCidrError {
    #[error("no subnets of this size are available in the parent")]
    NoAvailableSubnets,
}

pub async fn allocate_cidr(
    connection: &mut AsyncPgConnection,
    parent: &AddressAllocation,
    name: String,
    width: u8,
) -> anyhow::Result<AddressAllocation> {
    for candidate in parent.cidr.subnets(width)? {
        use crate::schema::address_allocation::dsl;

        let existing: Option<crate::models::AddressAllocation> = dsl::address_allocation
            .filter(
                dsl::parent_id
                    .eq(parent.id)
                    .and(dsl::cidr.overlaps_with(candidate)),
            )
            .first(connection)
            .await
            .optional()?;

        if existing.is_some() {
            continue;
        }

        let allocation = crate::models::AddressAllocation {
            id: Uuid::now_v7(),
            name,
            parent_id: Some(parent.id),
            cidr: candidate,
        };

        insert_into(dsl::address_allocation)
            .values(&allocation)
            .execute(connection)
            .await?;

        return Ok(allocation);
    }

    Err(AllocateCidrError::NoAvailableSubnets.into())
}
