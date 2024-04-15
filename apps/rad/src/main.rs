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
        let closure_path = tokio::fs::canonicalize("/nix/var/nix/profiles/system").await?;
        let closure_path = closure_path.to_string_lossy();

        let mut transaction = pool.begin().await?;

        query!("INSERT INTO hosts(hostname, last_seen) VALUES($1, NOW()) ON CONFLICT(hostname) DO UPDATE SET last_seen=NOW()", &hostname)
            .execute(&mut *transaction)
            .await?;

        query!(
            "
            UPDATE 
                hosts 
            SET 
                last_running_closure_change = CASE 
                    WHEN running_closure_path != $1 OR last_running_closure_change IS NULL THEN NOW()  
                    ELSE last_running_closure_change 
                END,
                running_closure_path=$1
            WHERE hostname=$2",
            &closure_path,
            &hostname
        )
        .execute(&mut *transaction)
        .await?;

        transaction.commit().await?;

        println!("Updated host {hostname} with closure {closure_path}");

        sleep(Duration::from_secs(60)).await;
    }
}
