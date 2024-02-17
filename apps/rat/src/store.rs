use std::{collections::HashMap, path::PathBuf, time::Duration};

use thiserror::Error;

use crate::todo::{Id, IdGenerator, Priority, Status, Todo};

pub struct Store {
    path: PathBuf,
}

#[derive(Debug, Error)]
pub enum Error {
    #[error("A todo with id {0} does not exist")]
    DoesNotExist(Id),
}

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
        depends_on: Vec<Id>,
    ) -> Result<Id, Error> {
        let mut todos = self.read();
        let mut id_generator =
            IdGenerator::new(todos.values().map(|x| x.id().0).max().unwrap_or(0));

        for dependency_id in &depends_on {
            if !todos.contains_key(dependency_id) {
                return Err(Error::DoesNotExist(*dependency_id));
            }
        }

        let id = id_generator.next();

        let new_todo = Todo::new(id, title, priority, depends_on, estimate);
        todos.insert(id, new_todo);

        self.write(&todos);

        Ok(id)
    }

    pub fn find_ready_to_do(&self) -> Vec<Todo> {
        let all_todos = self.read();
        let mut todos_to_consider = all_todos
            .values()
            .filter(|v| v.status() == crate::todo::Status::Todo)
            .filter(|v| {
                v.depends_on()
                    .iter()
                    .filter(|x| all_todos.get(x).is_some_and(|y| y.status() == Status::Todo))
                    .count()
                    == 0
            })
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
