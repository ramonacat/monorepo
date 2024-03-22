use std::{fmt::Display, time::Duration};

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use strum::EnumIter;

pub mod client;

pub struct IdGenerator(usize);

impl IdGenerator {
    pub fn new(seed: usize) -> Self {
        Self(seed)
    }

    pub fn next(&mut self) -> Id {
        self.0 += 1;
        Id(self.0)
    }
}

#[derive(PartialEq, Eq, Hash, Copy, Clone, Debug, Deserialize, Serialize)]
pub struct Id(pub usize);

impl Display for Id {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, EnumIter)]
pub enum Priority {
    Low,
    Medium,
    High,
}

impl Display for Priority {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "{}",
            match self {
                Priority::Low => "Low",
                Priority::Medium => "Medium",
                Priority::High => "High",
            }
        )
    }
}

impl Default for Priority {
    fn default() -> Self {
        Self::Medium
    }
}

#[derive(Debug, Deserialize, Serialize, Clone, PartialEq, Eq, Copy)]
pub enum Status {
    Todo,
    Doing,
    Done,
}

impl Default for Status {
    fn default() -> Self {
        Self::Todo
    }
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub enum Requirement {
    TodoDone(Id),
    AfterDate(DateTime<Utc>),
}

impl Display for Requirement {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Requirement::TodoDone(id) => write!(f, "done({id})"),
            Requirement::AfterDate(when) => write!(f, "after({when})"),
        }
    }
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct Todo {
    id: Id,
    title: String,
    requirements: Vec<Requirement>,
    #[serde(default)]
    priority: Priority,
    #[serde(default)]
    status: Status,
    #[serde(default)]
    estimate: Duration,
}

impl Todo {
    pub fn new(
        id: Id,
        title: String,
        priority: Priority,
        requirements: Vec<Requirement>,
        estimate: Duration,
    ) -> Self {
        Self {
            id,
            title,
            requirements,
            priority,
            status: Status::Todo,
            estimate,
        }
    }

    pub fn id(&self) -> Id {
        self.id
    }

    pub fn requirements(&self) -> &[Requirement] {
        &self.requirements
    }

    pub fn title(&self) -> &str {
        &self.title
    }

    pub fn priority(&self) -> Priority {
        self.priority
    }

    pub fn add_requirement(&mut self, requirement: Requirement) {
        self.requirements.push(requirement);
    }

    pub fn set_priority(&mut self, priority: Priority) {
        self.priority = priority;
    }

    pub fn status(&self) -> Status {
        self.status
    }

    pub fn estimate(&self) -> Duration {
        self.estimate
    }

    pub fn set_estimate(&mut self, estimate: Duration) {
        self.estimate = estimate;
    }

    pub fn set_title(&mut self, title: String) {
        self.title = title;
    }

    pub fn transition_to(&mut self, status: Status) {
        self.status = status;
    }
}

#[cfg(test)]
mod test {
    use super::IdGenerator;

    #[test]
    pub fn generate_next_id() {
        let mut generator = IdGenerator::new(12);

        assert_eq!(13, generator.next().0);
        assert_eq!(14, generator.next().0);
    }
}
