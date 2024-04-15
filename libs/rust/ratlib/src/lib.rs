use std::time::Duration;

use chrono::DateTime;
use chrono_tz::Tz;
use serde::{Deserialize, Serialize};
use todo::{Priority, Requirement, Status};

use crate::datetime::{
    deserialize_date_time_tz, deserialize_date_time_tz_option, serialize_date_time_tz,
    serialize_date_time_tz_option,
};

pub mod calendar;
pub mod datetime;
pub mod secrets;
pub mod todo;
pub mod herd;

#[derive(Debug, Deserialize, Serialize)]
pub enum PostTodo {
    Add {
        title: String,
        priority: Priority,
        estimate: Duration,
        requirements: Vec<Requirement>,
        #[serde(
            serialize_with = "serialize_date_time_tz_option",
            deserialize_with = "deserialize_date_time_tz_option"
        )]
        deadline: Option<DateTime<Tz>>,
    },
}

#[derive(Debug, Deserialize, Serialize)]
pub enum PostTodoWithId {
    MoveToStatus(Status),
    Edit {
        set_title: Option<String>,
        set_estimate: Option<Duration>,
        add_requirements: Vec<Requirement>,
        set_priority: Option<Priority>,
    },
}

#[derive(Debug, Deserialize, Serialize)]
pub enum PostEvent {
    Add {
        #[serde(
            serialize_with = "serialize_date_time_tz",
            deserialize_with = "deserialize_date_time_tz"
        )]
        date: DateTime<Tz>,
        duration: Duration,
        title: String,
    },
}
