use std::{error::Error, time::Duration};

use sqlx::{postgres::PgPoolOptions, query};
use tokio::time::sleep;

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    let database_url = std::env::var("DATABASE_URL").unwrap();
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await?;

    sqlx::migrate!("./migrations/").run(&pool).await?;

    loop {
        let hostname = hostname::get()?.to_string_lossy().to_string();

        query!("INSERT INTO hosts(hostname, last_seen) VALUES($1, NOW()) ON CONFLICT(hostname) DO UPDATE SET last_seen=NOW()", &hostname)
            .execute(&pool)
            .await?;

        sleep(Duration::from_secs(60)).await;
    }
}
