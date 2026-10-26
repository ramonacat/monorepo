use serde::Deserialize;
use std::{sync::Arc, time::Duration};
use uuid::Uuid;

use futures::StreamExt as _;
use k8s_openapi::{
    api::core::v1::{PortStatus, Service},
    serde_json::json,
};
use kube::{
    Api, Client,
    api::{Patch, PatchParams},
    runtime::{Controller, controller::Action, reflector::Lookup, watcher},
};
use rlib::{
    load_balancers::{ServicePort, ServiceProtocol},
    ras_client::{RasClient, RasConnectionConfig},
};
use thiserror::Error;
use tracing::{debug, error, info, warn};

#[derive(Debug, Deserialize)]
struct Config {
    host_group_id: Uuid,
}

#[derive(Debug, Error)]
enum Error {
    #[error("invalid load balancer id: {0}")]
    InvalidBalancerId(uuid::Error),
    #[error("failed to read config: {0}")]
    FailedToReadConfig(anyhow::Error),
    #[error("failed to patch service: {0}")]
    FailedToPatchService(kube::Error),
    #[error("failed to update ras: {0}")]
    FailedToUpdateRas(anyhow::Error),
}

struct Data {
    ras_client: RasClient,
    client: Client,
}

fn error_policy(_service: Arc<Service>, _error: &Error, _data: Arc<Data>) -> Action {
    Action::requeue(Duration::from_secs(5))
}

const ANNOTATION_LOAD_BALANCER_ID: &str = "kube.names.ramona.fun/load-balancer-id";

#[tracing::instrument(skip_all, fields(service))]
async fn reconcile(service: Arc<Service>, data: Arc<Data>) -> Result<Action, Error> {
    info!("reconciling");

    let action_requeue = Action::requeue(Duration::from_secs(10));

    let spec = service.spec.as_ref().unwrap();

    if spec.type_.as_deref() != Some("LoadBalancer")
        || spec.load_balancer_class.as_deref() != Some("ramona-internal")
    {
        debug!("ignoring, type or class not matching");

        return Ok(action_requeue);
    }

    let api: Api<Service> = Api::namespaced(data.client.clone(), &service.namespace().unwrap());

    let uuid: uuid::Uuid;
    if let Some(id) = service
        .metadata
        .annotations
        .as_ref()
        .and_then(|x| x.get(ANNOTATION_LOAD_BALANCER_ID))
    {
        uuid = id.parse().map_err(Error::InvalidBalancerId)?;
    } else {
        uuid = uuid::Uuid::now_v7();
        api.patch(
            service.name().unwrap().as_ref(),
            &PatchParams::apply("roperator"),
            &Patch::Apply(json!({
                "apiVersion": "v1",
                "kind": "Service",
                "metadata": {
                    "annotations": {
                        ANNOTATION_LOAD_BALANCER_ID: uuid
                    }
                }
            })),
        )
        .await
        .map_err(Error::FailedToPatchService)?;
    }

    let config: Config = rlib::config::load().map_err(Error::FailedToReadConfig)?;

    let spec_ports = spec.ports.clone().unwrap_or_default();
    let ports = spec_ports.iter().filter_map(|service_port| {
        let Some(node_port) = service_port.node_port else {
            warn!(?service, ?service_port, "no node port");

            return None;
        };

        let protocol = match &service_port.protocol {
            Some(x) if x == "TCP" => ServiceProtocol::Tcp,
            Some(x) if x == "UDP" => ServiceProtocol::Udp,
            _ => {
                warn!(?service, ?service_port, "unsuportted protocol");
                return None;
            }
        };

        Some(ServicePort {
            protocol,
            exposed_port: service_port.port.try_into().unwrap(),
            host_port: node_port.try_into().unwrap(),
        })
    });

    let ports: Vec<_> = ports.collect();
    let load_balancer_ip = data
        .ras_client
        .upsert_load_balancer(uuid, config.host_group_id, ports.clone())
        .await
        .map_err(Error::FailedToUpdateRas)?
        .ip_address;
    let port_statuses: Vec<_> = ports
        .iter()
        .map(|x| PortStatus {
            error: None,
            port: x.exposed_port.into(),
            protocol: match x.protocol {
                ServiceProtocol::Tcp => "TCP".to_string(),
                ServiceProtocol::Udp => "UDP".to_string(),
            },
        })
        .collect();
    api.patch_status(
        service.name().unwrap().as_ref(),
        &PatchParams::apply("roperator"),
        &Patch::Apply(json!({
            "apiVersion": "v1",
            "kind": "Service",
            "status": {
                "loadBalancer": {
                    "ingress": {
                        "ip": load_balancer_ip,
                        "ports": port_statuses
                    }
                }
            }
        })),
    )
    .await
    .map_err(Error::FailedToPatchService)?;

    Ok(action_requeue)
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt().init();

    let ras_client = RasClient::new(RasConnectionConfig::LocalUnencrypted).unwrap();

    let client = Client::try_default().await.unwrap();
    let api: Api<Service> = Api::all(client.clone());

    Controller::new(api, watcher::Config::default())
        .shutdown_on_signal()
        .run(
            reconcile,
            error_policy,
            Arc::new(Data { ras_client, client }),
        )
        .for_each(|result| async move {
            match result {
                Ok(o) => info!(?o, "reconciled"),
                Err(e) => error!(?e, "reconciliation failed"),
            }
        })
        .await;

    info!("terminating");
}
