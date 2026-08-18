use axum::{Json, extract};
use diesel::{
    BoolExpressionMethods as _, ExpressionMethods, OptionalExtension, define_sql_function,
    dsl::insert_into,
    query_dsl::methods::{FilterDsl, LimitDsl, OrderDsl},
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
    previous_store_path: Option<String>,
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
                    previous_store_path: Some(current.store_path),
                });
            }

            let latest_version: Option<crate::models::Version> = dsl::versions
                .filter(dsl::versioned_item.eq(&request.versioned_item))
                .order(dsl::version.desc())
                .limit(1)
                .first(connection)
                .await
                .optional()
                .unwrap();

            let new_version = latest_version.as_ref().map(|x| x.version).unwrap_or(0i64) + 1;

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
                previous_store_path: latest_version.map(|x| x.store_path),
            })
        })
        .await;

    Json(result.unwrap())
}

pub async fn post_version_check(
    extract::State(app_state): extract::State<AppState>,
    extract::Json(request): extract::Json<PostVersionRequest>,
) -> Json<PostVersionResponse> {
    use crate::schema::versions::dsl;

    let mut connection = app_state.db_connect().await;

    let latest_closure: Option<crate::models::Version> = dsl::versions
        .filter(dsl::versioned_item.eq(request.versioned_item))
        .order(dsl::version.desc())
        .first(&mut connection)
        .await
        .optional()
        .unwrap();

    Json(PostVersionResponse {
        version: latest_closure.as_ref().map_or_else(|| 1, |x| x.version + 1),
        updated: latest_closure
            .as_ref()
            .is_none_or(|x| x.store_path != request.store_path),
        previous_store_path: latest_closure.as_ref().map(|x| x.store_path.clone()),
    })
}
