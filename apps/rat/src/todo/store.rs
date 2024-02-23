use std::{collections::HashMap, path::PathBuf, time::Duration};

use chrono::Utc;
use thiserror::Error;

use crate::{
    datafile::DataFile,
    todo::{Id, IdGenerator, Priority, Requirement, Status, Todo},
};

pub struct Store {
    path: PathBuf,
}

#[derive(Debug, Error)]
pub enum Error {}

impl Store {
    pub fn new(path: PathBuf) -> Self {
        Self { path }
    }

    pub fn create(
        &mut self,
        title: String,
        priority: Priority,
        estimate: Duration,
        requirements: Vec<Requirement>,
    ) -> Id {
        let mut datafile = DataFile::open_path(&self.path);
        let mut id_generator =
            IdGenerator::new(datafile.todos.values().map(|x| x.id().0).max().unwrap_or(0));

        let id = id_generator.next();

        let new_todo = Todo::new(id, title, priority, requirements, estimate);
        datafile.todos.insert(id, new_todo);

        datafile.save(&self.path);

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
        let datafile = DataFile::open_path(&self.path);
        let mut todos_to_consider = datafile
            .todos
            .values()
            .filter(|v| v.status() == crate::todo::Status::Todo)
            .filter(|v| Self::evaluate_requirements(&datafile.todos, v.requirements()))
            .cloned()
            .collect::<Vec<_>>();

        todos_to_consider.sort_by_key(|b| std::cmp::Reverse(b.priority()));

        todos_to_consider
    }

    pub fn find_doing(&self) -> Vec<Todo> {
        let datafile = DataFile::open_path(&self.path);

        datafile
            .todos
            .into_values()
            .filter(|x| x.status() == Status::Doing)
            .collect()
    }

    pub fn find_by_id(&self, id: Id) -> Option<Todo> {
        let datafile = DataFile::open_path(&self.path);

        datafile.todos.get(&id).cloned()
    }

    pub fn save(&mut self, todo: Todo) {
        let mut datafile = DataFile::open_path(&self.path);

        datafile.todos.insert(todo.id(), todo);

        datafile.save(&self.path);
    }
}
