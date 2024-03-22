use std::time::Duration;

use crate::error_template::{AppError, ErrorTemplate};
use leptos::{html::Form, *};
use leptos_meta::*;
use leptos_router::*;
use ratlib::todo::{Priority, Todo};
use strum::IntoEnumIterator;

#[component]
pub fn App() -> impl IntoView {
    // Provides context that manages stylesheets, titles, meta tags, etc.
    provide_meta_context();

    view! {
        <Stylesheet id="leptos" href="/pkg/ratweb.css"/>
        <Title text="Welcome to Leptos"/>

        <Router fallback=|| {
            let mut outside_errors = Errors::default();
            outside_errors.insert_with_default_key(AppError::NotFound);
            view! {
                <ErrorTemplate outside_errors/>
            }
            .into_view()
        }>
            <main>
                <Routes>
                    <Route path="" view=HomePage ssr=SsrMode::Async />
                </Routes>
            </main>
        </Router>
    }
}

#[component]
fn HomePage() -> impl IntoView {
    let (todos_update, todos_update_set) = create_signal(0);
    view! {
        <InlineTodoCreation on_send=todos_update_set />
        <Todos update_signal=todos_update />
    }
}

#[component]
fn CompactTodo(todo: Todo) -> impl IntoView {
    let duration_seconds = todo.estimate().as_secs();
    let mut duration_formatted = String::new();
    if duration_seconds >= 3600 {
        duration_formatted += &format!("{} h ", duration_seconds / 3600);
    }
    if duration_seconds % 3600 != 0 {
        duration_formatted += &format!("{} min", (duration_seconds % 3600) / 60);
    }
    let estimate = duration_formatted;
    let title = todo.title().to_string();
    let priority = match todo.priority() {
        Priority::Low => "low",
        Priority::Medium => "medium",
        Priority::High => "high",
    }
    .to_string();
    let id = todo.id().0;
    let estimate: Option<_> = if estimate != "" {
        Some(view! {<span class="duration">{ move || estimate.clone() }</span>})
    } else {
        None
    };

    view! {
        <div class="todo -compact">
            <p class="title">{ move || title.clone() }</p>
            <p class="meta">
                <span class="id">"id:" { move || id.clone() }</span>
                " "
                {estimate}
                " "
                <span class="priority">{ move || priority.clone() }</span>
            </p>
        </div>
    }
}

#[server(FindReadyToDo, "/api")]
pub async fn find_ready_to_do() -> Result<Vec<Todo>, ServerFnError> {
    let client = ratlib::todo::client::Client::new("http://hallewell:8438/");
    Ok(client.find_ready_to_do().await)
}

#[server(FindDoing, "/api")]
pub async fn find_doing() -> Result<Vec<Todo>, ServerFnError> {
    let client = ratlib::todo::client::Client::new("http://hallewell:8438/");
    Ok(client.find_doing().await)
}

#[component]
fn Todos(update_signal: ReadSignal<usize>) -> impl IntoView {
    let todos = create_resource(
        move || update_signal.get(),
        |_| async move { find_ready_to_do().await.unwrap() },
    );

    let doing = create_resource(
        move || update_signal.get(),
        |_| async move { find_doing().await.unwrap() },
    );

    view! {
        <Suspense>
            <h1>"Currently doing"</h1>
            <ul class="todo-list">
                {move || doing.get().map(|y| y.iter().map(|x| view! { <li><CompactTodo todo=x.clone() /></li> }).collect::<Vec<_>>())}
            </ul>

            <h1>"Ready to do"</h1>
            <ul class="todo-list">
            {
                move || todos.get().map(|y| y.iter().map(|x| view! { <li><CompactTodo todo=x.clone() /></li> }).collect::<Vec<_>>())
            }
            </ul>
        </Suspense>
    }
}

#[server(AddTodo, "/api")]
pub async fn add_todo(
    title: String,
    priority: Priority,
    estimate: u64,
) -> Result<(), ServerFnError> {
    let client = ratlib::todo::client::Client::new("http://hallewell:8438/");

    client
        .create(title, priority, Duration::from_secs(estimate * 60), vec![])
        .await;

    Ok(())
}

#[component]
fn InlineTodoCreation(on_send: WriteSignal<usize>) -> impl IntoView {
    let add_todo = create_server_action::<AddTodo>();

    let node_ref_form: NodeRef<Form> = Default::default();

    let _ = watch(
        move || add_todo.version().get(),
        move |_, _, _| {
            // NOTE: this is a hack so the value changes so the the signal can be signaled more
            // than once
            // TODO: find a less hacky solution
            on_send.update(|x| *x += 1);

            if let Some(form) = node_ref_form.get() {
                form.reset();
            }
        },
        false,
    );

    view! {
        <ActionForm action=add_todo class="-inline todo-creation" node_ref=node_ref_form>
            <label for="inline-add-todo-title">Title</label>
            <input required type="text" id="inline-add-todo-title" name="title" placeholder="title" />

            <label for="inline-add-todo-priority">Priority</label>
            <select name="priority">
                {
                    || Priority::iter().map(|p| view! {
                        <option value={p.to_string()} selected={if p == Priority::Medium { Some("selected") } else {None} }>{p.to_string()}</option>
                    }).collect::<Vec<_>>()
                }
            </select>

            <label for="inline-add-todo-estimate">Estimate</label>
            <input required type="number" id="inline-add-todo-estimate" name="estimate" placeholder="estimate" class="-small" />
            <span class="input-addon">min</span>

            <input type="submit" value="add" />
        </ActionForm>
    }
}
