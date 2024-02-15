use std::fmt::Display;

use serde::{Deserialize, Serialize};

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

#[derive(Serialize, Deserialize, Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
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
                Priority::Low => "low",
                Priority::Medium => "medium",
                Priority::High => "high",
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
    New,
    InProgress,
    Done,
}

impl Default for Status {
    fn default() -> Self {
        Self::New
    }
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct Todo {
    id: Id,
    title: String,
    depends_on: Vec<Id>,
    #[serde(default)]
    priority: Priority,
    #[serde(default)]
    status: Status,
}

impl Todo {
    pub fn new(id: Id, title: String, priority: Priority, depends_on: Vec<Id>) -> Self {
        Self {
            id,
            title,
            depends_on,
            priority,
            status: Status::New,
        }
    }

    pub fn id(&self) -> Id {
        self.id
    }

    pub fn depends_on(&self) -> &[Id] {
        &self.depends_on
    }

    pub fn title(&self) -> &str {
        &self.title
    }

    pub fn priority(&self) -> Priority {
        self.priority
    }

    pub fn mark_done(&mut self) {
        self.status = Status::Done;
    }

    pub fn add_dependency(&mut self, id: Id) {
        self.depends_on.push(id);
    }

    pub fn set_priority(&mut self, priority: Priority) {
        self.priority = priority;
    }

    pub fn status(&self) -> Status {
        self.status
    }
}
