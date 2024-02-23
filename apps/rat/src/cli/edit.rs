use std::time::Duration;

use crate::{
    todo::store::Store,
    todo::{Id, Priority, Requirement},
};

pub fn execute(
    todo_store: &mut Store,
    id: Id,
    add_requirements: Option<Vec<Requirement>>,
    set_priority: Option<Priority>,
    set_estimate: Option<Duration>,
    set_title: Option<String>,
) {
    let todo = todo_store.find_by_id(id);
    if let Some(mut todo) = todo {
        if let Some(requirements) = add_requirements {
            for requirement in requirements {
                todo.add_requirement(requirement);
            }
        }

        if let Some(priority) = set_priority {
            todo.set_priority(priority);
        }

        if let Some(estimate) = set_estimate {
            todo.set_estimate(estimate);
        }

        if let Some(title) = set_title {
            todo.set_title(title);
        }

        todo_store.save(todo);
    } else {
        println!("No todo with id {id}");
    }
}
