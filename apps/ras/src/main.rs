mod app;

use std::{error::Error, net::SocketAddr, path::PathBuf, sync::Arc};

use app::AppState;
use axum::{
    routing::{get, post},
    Router,
};
use axum_tracing_opentelemetry::middleware::{OtelAxumLayer, OtelInResponseLayer};
use opentelemetry::KeyValue;
use opentelemetry_otlp::WithExportConfig;
use opentelemetry_sdk::{runtime::Tokio, Resource};
use tokio::sync::Mutex;
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

    let datafile_path: PathBuf = "/home/ramona/shared/todos.json".into();

    let router = Router::new()
        .route("/", get(app::index))
        .route("/todos", get(app::todos::get_todos))
        .route("/todos", post(app::todos::post_todos))
        .route("/todos/:id", post(app::todos::post_todos_with_id))
        .route("/events", get(app::events::get).post(app::events::post))
        .with_state(AppState {
            todo_store: Arc::new(Mutex::new(ratlib::todo::store::Store::new(
                datafile_path.clone(),
            ))),
            event_store: Arc::new(Mutex::new(ratlib::calendar::store::Store::new(
                datafile_path,
            ))),
        })
        .layer(OtelInResponseLayer)
        .layer(OtelAxumLayer::default());

    let addr: SocketAddr = "0.0.0.0:8438".parse()?;

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, router.into_make_service()).await?;

    Ok(())
}
