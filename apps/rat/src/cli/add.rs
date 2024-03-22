use std::time::Duration;

use crate::todo::{Priority, Requirement};

pub async fn execute(
    server_url: &str,
    title: &str,
    priority: Priority,
    estimate: Duration,
    requirements: Vec<Requirement>,
) {
    let client = ratlib::todo::client::Client::new(server_url);
    let id = client.create(title, priority, estimate, requirements).await;

    // TODO: Get the ID from the webservice here!
    println!("Inserted a new TODO with title \"{title}\" and ID {id}");
}
