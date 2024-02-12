use std::{collections::HashMap, path::PathBuf};

use thiserror::Error;

use crate::todo::{IdGenerator, Priority, Todo, TodoId};

pub struct TodoStore {
    path: PathBuf,
}

#[derive(Debug, Error)]
pub enum Error {
    #[error("A todo with id {0} does not exist")]
    DoesNotExist(TodoId),
}

impl TodoStore {
    pub fn new(path: PathBuf) -> Self {
        Self { path }
    }

    fn read(&self) -> HashMap<TodoId, Todo> {
        let raw_data = std::fs::read_to_string(&self.path).unwrap();
        serde_json::from_str(&raw_data).unwrap()
    }

    fn write(&mut self, todos: HashMap<TodoId, Todo>) {
        let serialized_data = serde_json::to_string_pretty(&todos).unwrap();

        std::fs::write(&self.path, serialized_data).unwrap();
    }

    pub fn create(
        &mut self,
        title: String,
        priority: Priority,
        depends_on: Vec<TodoId>,
    ) -> Result<TodoId, Error> {
        let mut todos = self.read();
        let mut id_generator =
            IdGenerator::new(todos.values().map(|x| x.id().0).max().unwrap_or(0));

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
            .filter(|v| {
                v.depends_on()
                    .iter()
                    .filter(|x| all_todos.get(x).map(|y| !y.done()).unwrap_or(false))
                    .count()
                    == 0
            })
            .cloned()
            .collect::<Vec<_>>();

        todos_to_consider.sort_by(|a, b| b.priority().cmp(&a.priority()));

        todos_to_consider
    }

    pub fn mark_as_done(&mut self, id: TodoId) -> Result<(), Error> {
        let mut todos = self.read();
        let Some(todo) = todos.get_mut(&id) else {
            return Err(Error::DoesNotExist(id));
        };

        todo.mark_done();

        self.write(todos);

        Ok(())
    }

    pub fn add_dependency(&mut self, id: TodoId, dependencies: Vec<TodoId>) -> Result<(), Error> {
        let mut todos = self.read();
        let Some(todo) = todos.get_mut(&id) else {
            return Err(Error::DoesNotExist(id));
        };

        for dependency_id in dependencies {
            todo.add_dependency(dependency_id);
        }

        self.write(todos);

        Ok(())
    }

    pub fn set_priority(&mut self, id: TodoId, priority: Priority) -> Result<(), Error> {
        let mut todos = self.read();
        let Some(todo) = todos.get_mut(&id) else {
            return Err(Error::DoesNotExist(id));
        };

        todo.set_priority(priority);

        self.write(todos);

        Ok(())
    }
}