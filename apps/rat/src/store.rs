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
            .filter(|v| v.status() == crate::todo::Status::New)
            .filter(|v| {
                v.depends_on()
                    .iter()
                    .filter(|x| all_todos.get(x).is_some_and(|y| y.status() == Status::New))
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
            .filter(|x| x.status() == Status::InProgress)
            .collect()
    }

    pub fn mark_as_done(&mut self, id: Id) -> Result<(), Error> {
        self.mutate(id, |todo| {
            todo.mark_done();

            Ok(())
        })
    }

    pub fn mark_as_doing(&mut self, id: Id) -> Result<(), Error> {
        self.mutate(id, |todo| {
            todo.mark_in_progress();

            Ok(())
        })
    }

    pub fn mark_as_todo(&mut self, id: Id) -> Result<(), Error> {
        self.mutate(id, |todo| {
            todo.mark_todo();

            Ok(())
        })
    }

    pub fn add_dependency(&mut self, id: Id, dependencies: Vec<Id>) -> Result<(), Error> {
        self.mutate(id, move |todo| {
            for dependency_id in dependencies {
                todo.add_dependency(dependency_id);
            }

            Ok(())
        })
    }

    pub fn set_priority(&mut self, id: Id, priority: Priority) -> Result<(), Error> {
        self.mutate(id, |todo| {
            todo.set_priority(priority);

            Ok(())
        })
    }

    pub(crate) fn set_estimate(&mut self, id: Id, estimate: Duration) -> Result<(), Error> {
        self.mutate(id, |todo| {
            todo.set_estimate(estimate);

            Ok(())
        })
    }

    fn mutate(
        &mut self,
        id: Id,
        action: impl FnOnce(&mut Todo) -> Result<(), Error>,
    ) -> Result<(), Error> {
        let mut todos = self.read();
        let Some(todo) = todos.get_mut(&id) else {
            return Err(Error::DoesNotExist(id));
        };

        let result = action(todo);

        self.write(&todos);

        result
    }
}
