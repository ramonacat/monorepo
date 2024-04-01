use std::time::Duration;

use chrono::DateTime;
use chrono_tz::Tz;

use crate::PostTodo;

use super::{Id, Priority, Requirement, Todo};

pub struct Client {
    server_url: String,
}

impl Client {
    pub fn new(server_url: impl Into<String>) -> Self {
        Self {
            server_url: server_url.into(),
        }
    }

    pub async fn find_doing(&self) -> Vec<Todo> {
        let client = reqwest::Client::new();

        client
            .get(format!("{}todos?status=Doing", self.server_url))
            .send()
            .await
            .unwrap()
            .json()
            .await
            .unwrap()
    }

    pub async fn find_around_deadline(&self) -> Vec<Todo> {
        let client = reqwest::Client::new();

        client
            .get(format!("{}todos?query=AroundDeadline", self.server_url))
            .send()
            .await
            .unwrap()
            .json()
            .await
            .unwrap()
    }

    pub async fn find_ready_to_do(&self) -> Vec<Todo> {
        let client = reqwest::Client::new();

        client
            .get(format!("{}todos", self.server_url))
            .send()
            .await
            .unwrap()
            .json()
            .await
            .unwrap()
    }

    pub async fn create(
        &self,
        title: impl Into<String>,
        priority: Priority,
        estimate: Duration,
        requirements: Vec<Requirement>,
        deadline: Option<DateTime<Tz>>,
    ) -> Id {
        let client = reqwest::Client::new();

        let id: Id = client
            .post(format!("{}todos", self.server_url))
            .json(&PostTodo::Add {
                title: title.into(),
                priority,
                estimate,
                requirements,
                deadline,
            })
            .send()
            .await
            .unwrap()
            .json()
            .await
            .unwrap();

        id
    }
}
