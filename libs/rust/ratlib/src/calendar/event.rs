use std::time::Duration;

use chrono::DateTime;
use chrono_tz::Tz;
use serde::{Deserialize, Serialize};

use crate::datetime::{deserialize_date_time_tz, serialize_date_time_tz};

#[derive(Serialize, Deserialize, Debug, Hash, Eq, PartialEq, Copy, Clone)]
pub struct Id(pub u32);

#[derive(Serialize, Deserialize, Debug)]
pub struct Event {
    id: Id,
    #[serde(
        serialize_with = "serialize_date_time_tz",
        deserialize_with = "deserialize_date_time_tz"
    )]
    start: DateTime<Tz>,
    duration: Duration,

    title: String,
}

impl Event {
    pub fn new(id: Id, start: DateTime<Tz>, duration: Duration, title: String) -> Self {
        Self {
            id,
            start,
            duration,
            title,
        }
    }

    pub fn start(&self) -> DateTime<Tz> {
        self.start
    }

    pub fn duration(&self) -> Duration {
        self.duration
    }

    pub fn title(&self) -> &str {
        &self.title
    }
}
