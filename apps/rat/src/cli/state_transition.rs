use ratlib::{PostTodoWithId, SERVER_URL};

use crate::todo::{Id, Status};

pub fn execute(id: Id, status: Status) {
    let client = reqwest::blocking::Client::new();

    client
        .post(format!("{}todos/{}", SERVER_URL, id.0))
        .json(&PostTodoWithId::MoveToStatus(status))
        .send()
        .unwrap();
}
