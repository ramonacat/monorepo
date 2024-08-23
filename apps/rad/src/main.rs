use std::{error::Error, time::Duration};

use serde::Serialize;
use tokio::time::sleep;

#[derive(Serialize)]
struct PostSystemUpdateCurrentClosure {
    pub current_closure: String,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    let client = reqwest::Client::new();
    let user_token = ratlib::secrets::read("rad-ras-token")?;

    loop {
        let hostname = hostname::get()?.to_string_lossy().to_string();
        let closure_path = tokio::fs::canonicalize("/nix/var/nix/profiles/system").await?;
        let closure_path = closure_path.to_string_lossy();

        let result = client
            .post("http://ras2.services.ramona.fun/systems")
            .json(&PostSystemUpdateCurrentClosure {
                current_closure: closure_path.to_string(),
            })
            .header("X-Action", "update-current-closure")
            .header("X-User-Token", user_token.trim())
            .send()
            .await?
            .status();

        println!("Updated host {hostname} with closure {closure_path}, response: {result}");

        sleep(Duration::from_secs(60)).await;
    }
}
