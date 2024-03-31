use reqwest::StatusCode;

use crate::MaintenanceAction;

pub async fn execute(server_url: &str, action: MaintenanceAction) {
    let client = reqwest::Client::new();

    match action {
        MaintenanceAction::Monitoring => {
            let response = client
                .post(format!("{server_url}maintenance/monitoring"))
                .send()
                .await
                .unwrap();

            assert!(
                response.status() == StatusCode::OK,
                "Failed to execute monitoring maintenance"
            );
        }
    }
}
