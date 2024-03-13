use std::time::Duration;

use ratlib::{todo::Id, PostTodo, SERVER_URL};

use crate::todo::{Priority, Requirement};

pub fn execute(
    title: &str,
    priority: Priority,
    estimate: Duration,
    requirements: Vec<Requirement>,
) {
    let client = reqwest::blocking::Client::new();

    let id: Id = client
        .post(format!("{}todos", SERVER_URL))
        .json(&PostTodo::Add {
            title: title.to_string(),
            priority,
            estimate,
            requirements,
        })
        .send()
        .unwrap()
        .json()
        .unwrap();

    // TODO: Get the ID from the webservice here!
    println!("Inserted a new TODO with title \"{title}\" and ID {id}");
}
