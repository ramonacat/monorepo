use std::{error::Error, net::SocketAddr};

use axum::{routing::get, Json, Router};
use axum_tracing_opentelemetry::middleware::{OtelAxumLayer, OtelInResponseLayer};
use opentelemetry::KeyValue;
use opentelemetry_otlp::WithExportConfig;
use opentelemetry_sdk::{runtime::Tokio, Resource};
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
        .with(EnvFilter::new("trace,h2=info,tower=info,hyper=info,tokio_util=info,tonic=info"))
        .with(fmt::layer())
        .with(tracing_layer)
        .init();

    let router = Router::new()
        .route("/", get(index))
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
