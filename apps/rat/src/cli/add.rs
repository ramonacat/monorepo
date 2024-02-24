use std::time::Duration;

use crate::{
    todo::store::Store,
    todo::{Priority, Requirement},
};

pub fn execute(
    todo_store: &mut Store,
    title: &str,
    priority: Priority,
    estimate: Duration,
    requirements: Vec<Requirement>,
) {
    let id = todo_store.create(title.to_string(), priority, estimate, requirements);

    println!("Inserted a new TODO with title \"{title}\" and ID {id}");
}
