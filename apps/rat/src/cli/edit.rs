use std::time::Duration;

use ratlib::PostTodoWithId;

use crate::todo::{Id, Priority, Requirement};

pub fn execute(
    server_url: &str,
    id: Id,
    add_requirements: Option<Vec<Requirement>>,
    set_priority: Option<Priority>,
    set_estimate: Option<Duration>,
    set_title: Option<String>,
) {
    let client = reqwest::blocking::Client::new();

    client
        .post(format!("{server_url}todos/{}", id.0))
        .json(&PostTodoWithId::Edit {
            set_title,
            set_estimate,
            add_requirements: add_requirements.unwrap_or_default(),
            set_priority,
        })
        .send()
        .unwrap();
}
