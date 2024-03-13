use crate::app::AppState;
use axum::{
    extract::{Path, State},
    Json,
};
use ratlib::{
    todo::{Id, Todo},
    PostTodo, PostTodoWithId,
};
use std::borrow::BorrowMut;

pub async fn get_todos(State(app_state): State<AppState>) -> Json<Vec<Todo>> {
    let mut store_mutex_guard = app_state.todo_store.lock().await;
    let store = store_mutex_guard.borrow_mut();

    Json(store.find_ready_to_do())
}

pub async fn post_todos(
    State(app_state): State<AppState>,
    Json(request): Json<PostTodo>,
) -> Json<Id> {
    let mut store_mutex_guard = app_state.todo_store.lock().await;
    let store = store_mutex_guard.borrow_mut();

    match request {
        PostTodo::Add {
            title,
            priority,
            estimate,
            requirements,
        } => {
            let id = store.create(title, priority, estimate, requirements);

            Json(id)
        }
    }
}

pub async fn post_todos_with_id(
    State(app_state): State<AppState>,
    Path(id): Path<Id>,
    Json(request): Json<PostTodoWithId>,
) -> Json<String> {
    let mut store_mutex_guard = app_state.todo_store.lock().await;
    let store = store_mutex_guard.borrow_mut();

    match request {
        PostTodoWithId::MoveToStatus(new_status) => {
            let mut todo = store.find_by_id(id).unwrap();
            todo.transition_to(new_status);
            store.save(todo);
        }
        PostTodoWithId::Edit {
            set_title,
            set_estimate,
            add_requirements,
            set_priority,
        } => {
            let mut todo = store.find_by_id(id).unwrap();

            if let Some(title) = set_title {
                todo.set_title(title);
            }

            if let Some(estimate) = set_estimate {
                todo.set_estimate(estimate);
            }

            for requirement in add_requirements {
                todo.add_requirement(requirement);
            }

            if let Some(priority) = set_priority {
                todo.set_priority(priority);
            }

            store.save(todo);
        }
    }

    Json("ok".to_string())
}
