use std::env;

use axum::{
    Json, Router, extract,
    routing::{get, post},
};
use chrono::{DateTime, Utc};
use diesel::{Connection, ExpressionMethods, PgConnection, insert_into, upsert::excluded};
use diesel_async::{AsyncConnection as _, AsyncPgConnection, RunQueryDsl};
use diesel_migrations::{EmbeddedMigrations, MigrationHarness, embed_migrations};
use dotenvy::dotenv;
use serde::{Deserialize, Serialize};
use tracing::instrument;

use crate::models::ClosureState;

mod models;
mod schema;

pub const MIGRATIONS: EmbeddedMigrations = embed_migrations!("migrations/");

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt().init();
    dotenv().ok();

    let database_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    PgConnection::establish(&database_url)
        .expect("failed to connect to the database")
        .run_pending_migrations(MIGRATIONS)
        .unwrap();
    let app_state = AppState { database_url };

    let app = Router::new()
        .route("/", get(get_current_state))
        .route(
            "/hosts/{hostname}/current_closure",
            post(post_current_closure),
        )
        .route(
            "/hosts/{hostname}/latest_closure",
            post(post_latest_closure),
        )
        .with_state(app_state);

    // run our app with hyper, listening globally on port 3000
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();

    println!("done");
}

#[derive(Debug, Clone)]
struct AppState {
    database_url: String,
}

impl AppState {
    async fn db_connect(&self) -> AsyncPgConnection {
        AsyncPgConnection::establish(&self.database_url)
            .await
            .expect("database connection did not succeed")
    }
}

#[derive(Debug, Serialize, Deserialize)]
struct HostState {
    hostname: String,
    current_closure: Option<String>,
    current_closure_updated_at: Option<DateTime<Utc>>,
    latest_closure: Option<String>,
    latest_closure_updated_at: Option<DateTime<Utc>>,
    outdated: bool,
}

#[derive(Debug, Serialize, Deserialize)]
struct CurrentStateResponse {
    hosts: Vec<HostState>,
}

#[axum::debug_handler]
async fn get_current_state(
    extract::State(app_state): extract::State<AppState>,
) -> Json<CurrentStateResponse> {
    use self::schema::closure_state::dsl::*;

    let mut connection = app_state.db_connect().await;
    let states: Vec<ClosureState> = closure_state.load(&mut connection).await.unwrap();

    let hosts = states
        .into_iter()
        .map(|x| HostState {
            outdated: x.latest_closure != x.current_closure,

            hostname: x.hostname,
            current_closure: x.current_closure,
            current_closure_updated_at: x.current_closure_updated_at,
            latest_closure: x.latest_closure,
            latest_closure_updated_at: x.latest_closure_updated_at,
        })
        .collect();

    Json(CurrentStateResponse { hosts })
}

#[derive(Debug, Serialize, Deserialize)]
struct PostCurrentClosureRequest {
    current_closure: String,
}

#[axum::debug_handler]
#[instrument]
async fn post_current_closure(
    extract::State(app_state): extract::State<AppState>,
    extract::Path(hostname_value): extract::Path<String>,
    extract::Json(request): extract::Json<PostCurrentClosureRequest>,
) {
    use self::schema::closure_state::dsl::*;

    let mut connection = app_state.db_connect().await;

    insert_into(closure_state)
        .values((
            hostname.eq(hostname_value),
            current_closure.eq(Some(request.current_closure)),
            current_closure_updated_at.eq(Some(Utc::now())),
        ))
        .on_conflict(hostname)
        .do_update()
        .set((
            current_closure.eq(excluded(current_closure)),
            current_closure_updated_at.eq(excluded(current_closure_updated_at)),
        ))
        .execute(&mut connection)
        .await
        .unwrap();
}

#[derive(Debug, Serialize, Deserialize)]
struct PostLatestClosureRequest {
    latest_closure: String,
}

#[axum::debug_handler]
#[instrument]
async fn post_latest_closure(
    extract::State(app_state): extract::State<AppState>,
    extract::Path(hostname_value): extract::Path<String>,
    extract::Json(request): extract::Json<PostLatestClosureRequest>,
) {
    use self::schema::closure_state::dsl::*;

    let mut connection = app_state.db_connect().await;

    insert_into(closure_state)
        .values((
            hostname.eq(hostname_value),
            latest_closure.eq(Some(request.latest_closure)),
            latest_closure_updated_at.eq(Some(Utc::now())),
        ))
        .on_conflict(hostname)
        .do_update()
        .set((
            latest_closure.eq(excluded(latest_closure)),
            latest_closure_updated_at.eq(excluded(latest_closure_updated_at)),
        ))
        .execute(&mut connection)
        .await
        .unwrap();
}
