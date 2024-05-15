use std::{error::Error, time::Duration};

use ratlib::herd::PostHerdMachine;
use tokio::time::sleep;

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    let client = reqwest::Client::new();

    loop {
        let hostname = hostname::get()?.to_string_lossy().to_string();
        let closure_path = tokio::fs::canonicalize("/nix/var/nix/profiles/system").await?;
        let closure_path = closure_path.to_string_lossy();

        let result: String = client
            .post(format!("http://hallewell:8438/herd/machines/{hostname}"))
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
