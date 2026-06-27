use std::env;

use axum::{
    Router,
    routing::{delete, get, post},
};
use diesel::{Connection, PgConnection};
use diesel_async::{AsyncConnection as _, AsyncPgConnection};
use diesel_migrations::{EmbeddedMigrations, MigrationHarness, embed_migrations};
use dotenvy::dotenv;

mod hosts;
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
        .route("/hosts", get(hosts::get_current_state))
        .route("/hosts/{hostname}", delete(hosts::delete))
        .route(
            "/hosts/{hostname}/current_closure",
            post(hosts::post_current_closure),
        )
        .route(
            "/hosts/{hostname}/latest_closure",
            post(hosts::post_latest_closure),
        )
        .route(
            "/hosts/{hostname}/latest_closure",
            get(hosts::get_latest_closure),
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
