use std::time::Duration;

use serde::{Deserialize, Serialize};
use todo::{Priority, Requirement, Status};

pub mod calendar;
pub mod todo;

mod datafile;

// TODO: This should be read from the config...
pub const SERVER_URL:&str = "http://localhost:8438/";

#[derive(Debug, Deserialize, Serialize)]
pub enum PostTodo {
    Add { title: String, priority: Priority, estimate: Duration, requirements: Vec<Requirement>},
}

#[derive(Debug, Deserialize, Serialize)]
pub enum PostTodoWithId {
    MoveToStatus(Status),
    Edit { set_title: Option<String>, set_estimate: Option<Duration>, add_requirements: Vec<Requirement>, set_priority: Option<Priority> }
}
