use crate::{
    todo::store::Store,
    todo::{Id, Status},
};

pub fn execute(todo_store: &mut Store, id: Id, status: Status) {
    let todo = todo_store.find_by_id(id);
    if let Some(mut todo) = todo {
        todo.transition_to(status);
        todo_store.save(todo);
    } else {
        println!("No todo with id {id}");
    }
}
