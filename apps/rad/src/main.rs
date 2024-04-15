use std::{error::Error, time::Duration};

use ratlib::herd::PostHerdMachine;
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

    let client = reqwest::Client::new();

    loop {
        let hostname = hostname::get()?.to_string_lossy().to_string();
        let closure_path = tokio::fs::canonicalize("/nix/var/nix/profiles/system").await?;
        let closure_path = closure_path.to_string_lossy();

        let result: String = client
            .post(format!("http://localhost:8438/herd/machines/{hostname}"))
            .json(&PostHerdMachine {
                current_closure: closure_path.to_string(),
            })
            .send()
            .await?
            .json()
            .await?;

        println!("Updated host {hostname} with closure {closure_path}, response: {result}");

        sleep(Duration::from_secs(60)).await;
    }
}
