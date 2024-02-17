use std::{collections::HashMap, path::PathBuf, time::Duration};

use chrono::Utc;
use thiserror::Error;

use crate::todo::{Id, IdGenerator, Priority, Requirement, Status, Todo};

pub struct Store {
    path: PathBuf,
}

#[derive(Debug, Error)]
pub enum Error {}

impl Store {
    pub fn new(path: PathBuf) -> Self {
        Self { path }
    }

    fn read(&self) -> HashMap<Id, Todo> {
        let raw_data = std::fs::read_to_string(&self.path).unwrap();
        serde_json::from_str::<HashMap<Id, Todo>>(&raw_data).unwrap()
    }

    fn write(&mut self, todos: &HashMap<Id, Todo>) {
        let serialized_data = serde_json::to_string_pretty(&todos).unwrap();

        std::fs::write(&self.path, serialized_data).unwrap();
    }

    pub fn create(
        &mut self,
        title: String,
        priority: Priority,
        estimate: Duration,
        requirements: Vec<Requirement>,
    ) -> Id {
        let mut todos = self.read();
        let mut id_generator =
            IdGenerator::new(todos.values().map(|x| x.id().0).max().unwrap_or(0));

        let id = id_generator.next();

        let new_todo = Todo::new(id, title, priority, requirements, estimate);
        todos.insert(id, new_todo);

        self.write(&todos);

        id
    }

    // TODO: This should really be its own struct...
    fn evaluate_requirements(all_todos: &HashMap<Id, Todo>, requirements: &[Requirement]) -> bool {
        for requirement in requirements {
            match requirement {
                Requirement::TodoDone(id) => {
                    if !all_todos
                        .get(id)
                        .is_some_and(|x| x.status() == Status::Done)
                    {
                        return false;
                    }
                }
                Requirement::AfterDate(when) => {
                    if Utc::now() <= *when {
                        return false;
                    }
                }
            }
        }

        true
    }

    pub fn find_ready_to_do(&self) -> Vec<Todo> {
        let all_todos = self.read();
        let mut todos_to_consider = all_todos
            .values()
            .filter(|v| v.status() == crate::todo::Status::Todo)
            .filter(|v| Self::evaluate_requirements(&all_todos, v.requirements()))
            .cloned()
            .collect::<Vec<_>>();

        todos_to_consider.sort_by_key(|b| std::cmp::Reverse(b.priority()));

        todos_to_consider
    }

    pub fn find_doing(&self) -> Vec<Todo> {
        let all = self.read();

        all.into_values()
            .filter(|x| x.status() == Status::Doing)
            .collect()
    }

    pub fn find_by_id(&self, id: Id) -> Option<Todo> {
        let all = self.read();

        all.get(&id).cloned()
    }

    pub fn save(&mut self, todo: Todo) {
        let mut all_todos = self.read();

        all_todos.insert(todo.id(), todo);

        self.write(&all_todos);
    }
}
