use std::{collections::HashMap, path::PathBuf};

use thiserror::Error;

use crate::todo::{IdGenerator, Priority, Todo, TodoId};

pub struct TodoStore {
    path: PathBuf,
}

#[derive(Debug, Error)]
pub enum Error {
    #[error("A todo with id {0} does not exist")]
    DoesNotExist(TodoId)
}

impl TodoStore {
    pub fn new(path: PathBuf) -> Self {
        Self { path }
    }

    pub fn read(&self) -> HashMap<TodoId, Todo> {
        let raw_data = std::fs::read_to_string(&self.path).unwrap();
        serde_json::from_str(&raw_data).unwrap()
    }

    pub fn write(&mut self, todos: HashMap<TodoId, Todo>) {
        let serialized_data = serde_json::to_string_pretty(&todos).unwrap();

        std::fs::write(&self.path, serialized_data).unwrap();
    }

    pub fn create(&mut self, title: String, priority: Priority, depends_on: Vec<TodoId>) -> Result<TodoId, Error> {
        let mut todos = self.read();
        let mut id_generator = IdGenerator::new(todos.values().map(|x| x.id().0).max().unwrap_or(0));

        for dependency_id in &depends_on {
            if !todos.contains_key(dependency_id) {
                return Err(Error::DoesNotExist(*dependency_id));
            }
        }

        let id = id_generator.next();

        let new_todo = Todo::new(id, title, priority, depends_on);
        todos.insert(id, new_todo);

        self.write(todos);

        Ok(id)
    }

    pub fn find_ready_to_do(&self) -> Vec<Todo> {
        let all_todos = self.read();
        let mut todos_to_consider = all_todos
            .iter()
            .map(|(_, v)| v)
            .filter(|v| !v.done())
            .filter(|v| v.depends_on().iter().filter(|x| all_todos.get(x).map(|y| !y.done()).unwrap_or(false)).count() == 0)
            .cloned().collect::<Vec<_>>();

        todos_to_consider.sort_by(|a, b| { b.priority().cmp(&a.priority()) });

        todos_to_consider
    }
}
