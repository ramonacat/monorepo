use std::{error::Error, net::SocketAddr};

use axum::{
    extract::Path,
    routing::{get, post},
    Json, Router,
};
use axum_tracing_opentelemetry::middleware::{OtelAxumLayer, OtelInResponseLayer};
use opentelemetry::KeyValue;
use opentelemetry_otlp::WithExportConfig;
use opentelemetry_sdk::{runtime::Tokio, Resource};
use ratlib::{
    todo::{Id, Todo},
    PostTodo, PostTodoWithId,
};
use tracing_subscriber::{fmt, layer::SubscriberExt, util::SubscriberInitExt, EnvFilter, Registry};

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    let tracer = opentelemetry_otlp::new_pipeline()
        .tracing()
        .with_exporter(
            opentelemetry_otlp::new_exporter()
                .tonic()
                .with_endpoint("http://hallewell:4317"),
        )
        .with_trace_config(
            opentelemetry_sdk::trace::config()
                .with_resource(Resource::new(vec![KeyValue::new("service.name", "ras")])),
        )
        .install_batch(Tokio)?;

    let tracing_layer = tracing_opentelemetry::layer().with_tracer(tracer);

    Registry::default()
        .with(EnvFilter::new(
            "trace,h2=info,tower=info,hyper=info,tokio_util=info,tonic=info",
        ))
        .with(fmt::layer())
        .with(tracing_layer)
        .init();

    let router = Router::new()
        .route("/", get(index))
        .route("/todos", get(get_todos))
        .route("/todos", post(post_todos))
        .route("/todos/:id", post(post_todos_with_id))
        .layer(OtelInResponseLayer::default())
        .layer(OtelAxumLayer::default());

    let addr: SocketAddr = "0.0.0.0:8438".parse()?;

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, router.into_make_service()).await?;

    Ok(())
}

async fn index() -> Json<String> {
    Json("Hi".to_string())
}

async fn get_todos() -> Json<Vec<Todo>> {
    let store = ratlib::todo::store::Store::new("/home/ramona/shared/todos.json".into());

    Json(store.find_ready_to_do())
}

async fn post_todos(Json(request): Json<PostTodo>) -> Json<Id> {
    match request {
        PostTodo::Add {
            title,
            priority,
            estimate,
            requirements,
        } => {
            let mut store =
                ratlib::todo::store::Store::new("/home/ramona/shared/todos.json".into());

            let id = store.create(title, priority, estimate, requirements);

            Json(id)
        }
    }
}

async fn post_todos_with_id(
    Path(id): Path<Id>,
    Json(request): Json<PostTodoWithId>,
) -> Json<String> {
    match request {
        PostTodoWithId::MoveToStatus(new_status) => {
            let mut store =
                ratlib::todo::store::Store::new("/home/ramona/shared/todos.json".into());

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
            let mut store = ratlib::todo::store::Store::new("/home/ramona/shared/todos.json".into());

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
        },
    }

    Json("ok".to_string())
}
