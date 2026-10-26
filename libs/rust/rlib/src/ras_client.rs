use crate::ipam::PostIpamAllocateRequest;
use crate::ipam::PostIpamAllocateResponse;
use crate::load_balancers::ServicePort;
use crate::wireguard::GetTunnelsResponse;

use anyhow::Context;
use reqwest::{
    Identity, Url,
    header::{HeaderMap, HeaderName, HeaderValue},
};
use tracing::info;
use uuid::Uuid;

use crate::{
    host_identity::HostIdentity,
    hosts::{Hostname, PostHostStateRequest},
};

pub enum RasConnectionConfig {
    MTls(HostIdentity),
    // TODO this shouldn't really exist, it should always be over https and even internal services
    // should use some form of auth
    LocalUnencrypted,
}

pub struct RasClient {
    reqwest: reqwest::Client,
    base_url: Url,
}

impl RasClient {
    pub fn new(connection_config: RasConnectionConfig) -> anyhow::Result<Self> {
        let mut client_builder = reqwest::Client::builder();
        let mut headers = HeaderMap::new();

        let base_url = match connection_config {
            RasConnectionConfig::MTls(host_identity) => {
                let hostname = host_identity.hostname();
                let identity = Identity::from_pem(&host_identity.to_pem_bundle())?;
                client_builder = client_builder.identity(identity);

                headers.insert(
                    HeaderName::from_static("x-ramona-hostname"),
                    HeaderValue::from_str(hostname.first_label()).with_context(|| {
                        format!("failed to convert hostname {hostname:?} into a header value")
                    })?,
                );

                Url::parse("https://ras.ramona.fun:1443")?
            }
            RasConnectionConfig::LocalUnencrypted => Url::parse("http://ras.ras")?,
        };
        client_builder = client_builder.default_headers(headers);

        Ok(Self {
            reqwest: client_builder.build()?,
            base_url,
        })
    }

    pub async fn update_host_state(
        &self,
        hostname: &Hostname,
        state: &PostHostStateRequest,
    ) -> anyhow::Result<()> {
        let response = self
            .reqwest
            .post(self.make_url(&format!("/hosts/{}", hostname.first_label()))?)
            .json(state)
            .send()
            .await?
            .error_for_status()
            .with_context(|| format!("failed to update host {hostname:?}"))?;

        info!(?response, ?state, "updated host state");

        Ok(())
    }

    pub async fn get_wireguard_tunnels_for_host(
        &self,
        hostname: &Hostname,
    ) -> anyhow::Result<GetTunnelsResponse> {
        let response = self
            .reqwest
            .get(self.make_url(&format!("/hosts/{}/tunnels", hostname.first_label()))?)
            .send()
            .await?
            .error_for_status()?;

        Ok(response.json().await?)
    }

    pub async fn ip_allocate(
        &self,
        parent_id: Uuid,
        name: String,
        prefix_length: u8,
    ) -> anyhow::Result<PostIpamAllocateResponse> {
        let response = self
            .reqwest
            .post(self.make_url("/ip/actions/allocate")?)
            .json(&PostIpamAllocateRequest {
                parent_id,
                name,
                prefix_length,
            })
            .send()
            .await?
            .error_for_status()?;

        Ok(response.json().await?)
    }

    pub async fn upsert_load_balancer(
        &self,
        id: Uuid,
        host_group_id: Uuid,
        ports: Vec<ServicePort>,
    ) -> anyhow::Result<crate::load_balancers::PostUpsertResponse> {
        Ok(self
            .reqwest
            .post(self.make_url(&format!("/load_balancer/{}", id))?)
            .json(&crate::load_balancers::PostUpsertRequest {
                host_group_id,
                ports,
            })
            .send()
            .await?
            .error_for_status()?
            .json()
            .await?)
    }

    fn make_url(&self, path: &str) -> anyhow::Result<Url> {
        Ok(self.base_url.join(path)?)
    }
}
