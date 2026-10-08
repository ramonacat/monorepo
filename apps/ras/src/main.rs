use std::env;

use axum::{
    Router, extract,
    routing::{delete, get, post},
};
use dotenvy::dotenv;
use sqlx::{Connection, PgConnection, migrate::Migrator};
use tracing::{Level, instrument};

use crate::versions::{post_version, post_version_check};

mod homes;
mod hosts;
mod services;
mod versions;
mod wireguard;

pub const MIGRATOR: Migrator = sqlx::migrate!();

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_max_level(Level::TRACE)
        .init();
    dotenv().ok();

    // TODO make DATABASE_URL a part of the config file
    let database_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");

    let mut connection = sqlx::postgres::PgConnection::connect(&database_url)
        .await
        .expect("failed to connect to the database");
    MIGRATOR.run(&mut connection).await.unwrap();

    let app_state = AppState { database_url };

    let app = Router::new()
        .route("/", get(async || "ok"))
        .route("/health", get(get_health))
        .route("/hosts", get(hosts::get_current_state))
        .route(
            "/hosts/{hostname}",
            delete(hosts::delete).post(hosts::post_host_state),
        )
        .route("/hosts/{hostname}/tunnels", get(wireguard::get_tunnels))
        .route(
            "/hosts/{hostname}/current_closure",
            post(hosts::post_current_closure),
        )
        .route(
            "/hosts/{hostname}/latest_closure",
            post(hosts::post_latest_closure).get(hosts::get_latest_closure),
        )
        .route("/homes", get(homes::get_current_state))
        .route(
            "/homes/{name}/latest_closure",
            post(homes::post_latest_closure).get(homes::get_latest_closure),
        )
        .route(
            "/homes/{name}/current_closure/{hostname}",
            post(homes::post_current_closure),
        )
        .route("/versions", post(post_version))
        .route("/versions/actions/check", post(post_version_check))
        .with_state(app_state);

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();

    println!("done");
}

#[derive(Debug, Clone)]
struct AppState {
    database_url: String,
}

impl AppState {
    async fn db_connect(&self) -> PgConnection {
        PgConnection::connect(&self.database_url)
            .await
            .expect("database connection did not succeed")
    }
}

#[instrument]
#[axum::debug_handler]
async fn get_health(extract::State(app_state): extract::State<AppState>) {
    app_state.db_connect().await;
}
