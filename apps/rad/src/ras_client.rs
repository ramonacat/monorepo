use std::str::FromStr;

use anyhow::Context;
use reqwest::{
    Identity, Url,
    header::{HeaderMap, HeaderName, HeaderValue},
};
use rlib::hosts::PostHostStateRequest;
use tracing::info;

use crate::host::identity::HostIdentity;

pub struct RasClient {
    reqwest: reqwest::Client,
    host_identity: HostIdentity,
}

impl RasClient {
    pub fn new(host_identity: HostIdentity) -> anyhow::Result<Self> {
        let hostname = host_identity.hostname();
        let mut headers = HeaderMap::new();
        headers.insert(
            HeaderName::from_static("x-ramona-hostname"),
            HeaderValue::from_str(hostname).with_context(|| {
                format!("failed to convert hostname {hostname} into a header value")
            })?,
        );
        let identity = Identity::from_pem(&host_identity.to_pem_bundle())?;
        let client = reqwest::Client::builder()
            .identity(identity)
            .default_headers(headers)
            .build()?;

        Ok(Self {
            reqwest: client,
            host_identity,
        })
    }

    pub async fn update_host_state(&self, state: &PostHostStateRequest) -> anyhow::Result<()> {
        let hostname = self.host_identity.hostname();

        let response = self
            .reqwest
            .post(self.make_url(&format!("/hosts/{hostname}"))?)
            .json(state)
            .send()
            .await?
            .error_for_status()
            .with_context(|| format!("failed to update host {hostname}"))?;

        info!(?response, ?state, "updated host state");

        Ok(())
    }

    fn make_url(&self, path: &str) -> anyhow::Result<Url> {
        let base = Url::from_str("https://ras.ramona.fun:1443/")?;

        Ok(base.join(path)?)
    }
}
