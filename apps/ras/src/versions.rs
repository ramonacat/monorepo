use axum::{Json, extract};
use diesel::{
    BoolExpressionMethods as _, ExpressionMethods, OptionalExtension, define_sql_function,
    dsl::insert_into,
    query_dsl::methods::{FilterDsl, LimitDsl, OrderDsl, SelectDsl as _},
    sql_types::{BigInt, Nullable},
};
use diesel_async::{AsyncConnection, RunQueryDsl};
use serde::{Deserialize, Serialize};

use crate::AppState;

#[derive(Debug, Serialize, Deserialize)]
pub struct PostVersionRequest {
    versioned_item: String,
    store_path: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PostVersionResponse {
    version: i64,
    updated: bool,
}

define_sql_function! { fn coalesce(x: Nullable<BigInt>, y: BigInt) -> BigInt; }

pub async fn post_version(
    extract::State(app_state): extract::State<AppState>,
    extract::Json(request): extract::Json<PostVersionRequest>,
) -> Json<PostVersionResponse> {
    use crate::schema::versions::dsl;

    let mut connection = app_state.db_connect().await;
    let result = connection
        .transaction::<_, diesel::result::Error, _>(async |connection| {
            let current: Option<crate::models::Version> = dsl::versions
                .filter(
                    dsl::versioned_item
                        .eq(&request.versioned_item)
                        .and(dsl::store_path.eq(&request.store_path)),
                )
                .first(connection)
                .await
                .optional()
                .unwrap();

            if let Some(current) = current {
                return Ok(PostVersionResponse {
                    version: current.version,
                    updated: false,
                });
            }

            let new_version = dsl::versions
                .select(dsl::version)
                .filter(dsl::versioned_item.eq(&request.versioned_item))
                .order(dsl::version.desc())
                .limit(1)
                .first(connection)
                .await
                .optional()
                .unwrap()
                .unwrap_or(0i64)
                + 1;

            insert_into(dsl::versions)
                .values((
                    dsl::versioned_item.eq(request.versioned_item),
                    dsl::store_path.eq(request.store_path),
                    dsl::version.eq(new_version),
                ))
                .execute(connection)
                .await
                .unwrap();

            Ok(PostVersionResponse {
                version: new_version,
                updated: true,
            })
        })
        .await;

    Json(result.unwrap())
}
