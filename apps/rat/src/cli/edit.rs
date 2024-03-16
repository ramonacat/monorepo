use std::time::Duration;

use ratlib::PostTodoWithId;

use crate::todo::{Id, Priority, Requirement};

pub fn execute(
    server_url: String,
    id: Id,
    add_requirements: Option<Vec<Requirement>>,
    set_priority: Option<Priority>,
    set_estimate: Option<Duration>,
    set_title: Option<String>,
) {
    let client = reqwest::blocking::Client::new();

    client
        .post(format!("{}todos/{}", server_url, id.0))
        .json(&PostTodoWithId::Edit {
            set_title,
            set_estimate,
            add_requirements: add_requirements.unwrap_or(vec![]),
            set_priority,
        })
        .send()
        .unwrap();
}
