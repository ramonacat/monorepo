use std::{net::IpAddr, sync::Arc, time::Duration};

use futures::StreamExt;
use gateway_api::{gateways::Gateway, listenersets::ListenerSet};
use kube::{
    Api, Client,
    runtime::{Controller, controller::Action, watcher},
};
use rlib::ras_client::RasClient;
use thiserror::Error;
use tracing::{error, info};

struct Data {}

#[derive(Debug, Error)]
enum Error {
    #[error("failed to load the config: {0}")]
    ConfigLoadFailed(anyhow::Error),
    #[error("failed to find gateway: {0}")]
    FailedToFindGateway(kube::Error),
    #[error("unsupported gateway {group:?}/{kind} in {namespace}/{name}")]
    UnsupportedGateway {
        group: Option<String>,
        kind: String,
        namespace: String,
        name: String,
    },
    #[error("failed to update records: {0}")]
    FailedToUpdateRecords(anyhow::Error),
}

async fn resolve_parent_ref_to_addresses(
    client: &Client,
    group: Option<&str>,
    kind: &str,
    namespace: &str,
    name: &str,
) -> Result<Vec<IpAddr>, Error> {
    if group != Some("gateway.networking.k8s.io") {
        return Err(Error::UnsupportedGateway {
            group: group.map(std::string::ToString::to_string),
            kind: kind.to_string(),
            namespace: namespace.to_string(),
            name: name.to_string(),
        });
    }

    if kind == "Gateway" {
        let api_gateway: Api<Gateway> = Api::namespaced(client.clone(), namespace);

        let addresses = api_gateway
            .get(name)
            .await
            .map_err(Error::FailedToFindGateway)?
            .status
            .unwrap_or_default()
            .addresses
            .unwrap_or_default()
            .iter()
            .filter_map(|x| x.value.parse::<IpAddr>().ok())
            .collect();
        Ok(addresses)
    } else if kind == "ListenerSet" {
        let api_listener_set: Api<ListenerSet> = Api::namespaced(client.clone(), namespace);

        let listener_set = api_listener_set
            .get(name)
            .await
            .map_err(Error::FailedToFindGateway)?;

        let listener_set_parent = listener_set.spec.parent_ref;

        return Box::pin(resolve_parent_ref_to_addresses(
            client,
            listener_set_parent.group.as_deref(),
            &listener_set_parent.kind.unwrap_or_default(),
            &listener_set_parent
                .namespace
                .or(listener_set.metadata.namespace)
                .unwrap(),
            &listener_set_parent.name,
        ))
        .await;
    } else {
        Err(Error::UnsupportedGateway {
            group: group.map(std::string::ToString::to_string),
            kind: kind.to_string(),
            namespace: namespace.to_string(),
            name: name.to_string(),
        })
    }
}

fn hostnames_to_zones(
    route: &Arc<gateway_api::httproutes::HttpRoute>,
    config: &crate::Config,
) -> Vec<(String, String)> {
    route
        .spec
        .hostnames
        .iter()
        .flatten()
        .filter_map(move |x| {
            config
                .dns_zones
                .iter()
                .find(|zone| x.ends_with(*zone))
                .map(move |zone| (zone.clone(), x.clone()))
        })
        .collect()
}

pub async fn controller(ras_client: RasClient, client: Client) {
    let api: Api<gateway_api::httproutes::HttpRoute> = Api::all(client.clone());

    Controller::new(api, watcher::Config::default())
        .shutdown_on_signal()
        .run(
            |route, _data| {
                let client = client.clone();
                let ras_client = ras_client.clone();

                async move {
                    let action_requeue = Action::requeue(Duration::from_secs(10));

                    let config: crate::Config =
                        rlib::config::load().map_err(Error::ConfigLoadFailed)?;
                    let hostnames: Vec<_> = hostnames_to_zones(&route.clone(), &config);

                    if hostnames.is_empty() {
                        return Ok(action_requeue);
                    }

                    for parent in route
                        .status
                        .as_ref()
                        .map(|x| x.parents.clone())
                        .iter()
                        .flatten()
                    {
                        let addresses = resolve_parent_ref_to_addresses(
                            &client,
                            parent.parent_ref.group.as_deref(),
                            &parent.parent_ref.kind.clone().unwrap_or_default(),
                            &parent
                                .parent_ref
                                .namespace
                                .clone()
                                .or_else(|| route.metadata.namespace.clone())
                                .unwrap(),
                            &parent.parent_ref.name,
                        )
                        .await;

                        match addresses {
                            Ok(ips) => {
                                let ipv4: Vec<_> = ips
                                    .iter()
                                    .filter_map(|x| match x {
                                        IpAddr::V4(ipv4_addr) => Some(ipv4_addr),
                                        IpAddr::V6(_) => None,
                                    })
                                    .map(std::string::ToString::to_string)
                                    .collect();
                                let ipv6: Vec<_> = ips
                                    .iter()
                                    .filter_map(|x| match x {
                                        IpAddr::V4(_) => None,
                                        IpAddr::V6(ipv6_addr) => Some(ipv6_addr),
                                    })
                                    .map(std::string::ToString::to_string)
                                    .collect();

                                for (zone, hostname) in &hostnames {
                                    ras_client
                                        .upsert_dns_record(
                                            zone,
                                            &format!("{hostname}."),
                                            "A",
                                            ipv4.clone(),
                                            None,
                                        )
                                        .await
                                        .map_err(Error::FailedToUpdateRecords)?;
                                    ras_client
                                        .upsert_dns_record(
                                            zone,
                                            &format!("{hostname}."),
                                            "AAAA",
                                            ipv6.clone(),
                                            None,
                                        )
                                        .await
                                        .map_err(Error::FailedToUpdateRecords)?;
                                }
                            }
                            Err(e @ Error::UnsupportedGateway { .. }) => {
                                info!(?e, "skipping unsupported gateway");
                            }
                            Err(e) => return Err(e),
                        }
                    }

                    Ok::<_, Error>(Action::requeue(Duration::from_secs(10)))
                }
            },
            |_route, _error, _data| Action::requeue(Duration::from_secs(10)),
            Arc::new(Data {}),
        )
        .for_each(|result| async move {
            match result {
                Ok(o) => info!(?o, "reconciled"),
                Err(e) => error!(?e, "reconciliation failed"),
            }
        })
        .await;
}
