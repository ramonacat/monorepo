use axum::{
    Extension, Json, Router, extract,
    routing::{get, post},
};
use chrono::{DateTime, Days, Utc};
use diesel::{ExpressionMethods, delete, dsl::insert_into, query_dsl::methods::FilterDsl};
use diesel_async::RunQueryDsl;
use http::StatusCode;
use rand::{rngs::StdRng, seq::IndexedRandom};
use serde::{Deserialize, Serialize};
use thiserror::Error;
use uuid::Uuid;

use crate::{AppState, oauth::User, sessions::SessionHandle};

#[derive(Debug, Serialize)]
struct Token {
    name: String,
    expiration: DateTime<Utc>,
    value: String,
    id: Uuid,
}

#[derive(Debug, Serialize)]
struct GetTokensResponse {
    tokens: Vec<Token>,
}

#[derive(Debug, Serialize, Deserialize, Error)]
#[serde(tag = "kind")]
enum ApiError {
    #[error("not an admin")]
    NotAnAdmin,
}

#[axum::debug_handler]
async fn get_tokens(
    extract::Extension(state): extract::Extension<AppState>,
    user: User,
) -> Result<Json<GetTokensResponse>, (StatusCode, Json<ApiError>)> {
    if !user.is_admin() {
        return Err((StatusCode::UNAUTHORIZED, Json(ApiError::NotAnAdmin)));
    }

    use crate::schema::tokens::dsl::*;

    let mut connection = state.database.connect().await;
    let all_tokens: Vec<crate::models::Token> = tokens.load(&mut connection).await.unwrap();

    Ok(Json(GetTokensResponse {
        tokens: all_tokens.iter().map(map_token).collect(),
    }))
}

fn map_token(token: &crate::models::Token) -> Token {
    Token {
        id: token.id,
        name: token.name.clone(),
        expiration: token.expiration,
        value: token.value.clone(),
    }
}

async fn get_single_token(
    extract::Extension(state): extract::Extension<AppState>,
    extract::Path((_, token_id)): extract::Path<(String, Uuid)>,
    user: User,
) -> Result<Json<Token>, (StatusCode, Json<ApiError>)> {
    if !user.is_admin() {
        return Err((StatusCode::UNAUTHORIZED, Json(ApiError::NotAnAdmin)));
    }
    use crate::schema::tokens::dsl::*;

    let mut connection = state.database.connect().await;
    let the_token: crate::models::Token = tokens
        .filter(id.eq(token_id))
        .first(&mut connection)
        .await
        .unwrap();

    Ok(Json(map_token(&the_token)))
}

#[derive(Debug, Deserialize)]
struct PostTokensCreateRequest {
    name: String,
}

#[derive(Debug, Serialize)]
struct PostTokensCreateResponse {
    id: Uuid,
}

const TOKEN_ALPHABET: [&str; 12] = [
    "🍆",
    "🌮",
    "🖤",
    "⛓️",
    "🔒",
    "🔓",
    "🔑",
    "🗝️",
    "🪢",
    "🥺",
    "🍆🔒",
    "🍑💥🤚",
];

#[axum::debug_handler]
async fn post_tokens_create(
    extract::Extension(state): extract::Extension<AppState>,
    user: User,
    extract::Json(request): extract::Json<PostTokensCreateRequest>,
) -> Result<Json<PostTokensCreateResponse>, (StatusCode, Json<ApiError>)> {
    if !user.is_admin() {
        return Err((StatusCode::UNAUTHORIZED, Json(ApiError::NotAnAdmin)));
    }
    use crate::schema::tokens::dsl::*;

    let mut connection = state.database.connect().await;

    let mut rng: StdRng = rand::make_rng();
    let token_value = TOKEN_ALPHABET
        .choose_iter(&mut rng)
        .unwrap()
        .take(32)
        .fold(String::new(), |acc, x| acc + x);
    let token_id = Uuid::now_v7();

    insert_into(tokens)
        .values((
            id.eq(token_id),
            name.eq(request.name),
            value.eq(&token_value),
            expiration.eq(Utc::now() + Days::new(7)),
        ))
        .execute(&mut connection)
        .await
        .unwrap();

    Ok(Json(PostTokensCreateResponse { id: token_id }))
}

#[derive(Debug, Deserialize)]
struct PostTokensRevokeRequest {
    id: Uuid,
}

async fn post_tokens_revoke(
    extract::Extension(state): extract::Extension<AppState>,
    user: User,
    extract::Json(request): extract::Json<PostTokensRevokeRequest>,
) -> Result<(), (StatusCode, Json<ApiError>)> {
    if !user.is_admin() {
        return Err((StatusCode::UNAUTHORIZED, Json(ApiError::NotAnAdmin)));
    }
    use crate::schema::tokens::dsl::*;

    let mut connection = state.database.connect().await;

    delete(tokens.filter(id.eq(request.id)))
        .execute(&mut connection)
        .await
        .unwrap();

    Ok(())
}

async fn post_clear_own(session: extract::Extension<SessionHandle>) {
    session.update(|s| s.token = None).await;
}

pub fn router(state: AppState) -> Router<()> {
    Router::new()
        .route("/tokens", get(get_tokens))
        .route("/tokens/actions/create", post(post_tokens_create))
        .route("/tokens/actions/revoke", post(post_tokens_revoke))
        .route("/tokens/actions/clear-own", post(post_clear_own))
        .route("/tokens/{id}", get(get_single_token))
        .layer(Extension(state))
}
