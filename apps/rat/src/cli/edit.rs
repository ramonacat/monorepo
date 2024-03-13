use std::time::Duration;

use ratlib::{PostTodoWithId, SERVER_URL};

use crate::todo::{Id, Priority, Requirement};

pub fn execute(
    id: Id,
    add_requirements: Option<Vec<Requirement>>,
    set_priority: Option<Priority>,
    set_estimate: Option<Duration>,
    set_title: Option<String>,
) {
    let client = reqwest::blocking::Client::new();

    client
        .post(format!("{}todos/{}", SERVER_URL, id.0))
        .json(&PostTodoWithId::Edit {
            set_title,
            set_estimate,
            add_requirements: add_requirements.unwrap_or(vec![]),
            set_priority,
        })
        .send()
        .unwrap();
}
