use ratlib::PostTodoWithId;

use crate::todo::{Id, Status};

pub fn execute(server_url: &str, id: Id, status: Status) {
    let client = reqwest::blocking::Client::new();

    client
        .post(format!("{}todos/{}", server_url, id.0))
        .json(&PostTodoWithId::MoveToStatus(status))
        .send()
        .unwrap();
}
