use std::{ffi::OsString, fs};

use crate::config::Configuration;
use anyhow::Context;
use nix::unistd::gethostname;
use thiserror::Error;

pub struct HostIdentity {
    hostname: String,
    certificate: Vec<u8>,
    certificate_key: Vec<u8>,
}

impl HostIdentity {
    pub fn hostname(&self) -> &str {
        &self.hostname
    }

    pub fn to_pem_bundle(&self) -> Vec<u8> {
        Vec::from_iter(
            self.certificate_key
                .iter()
                .chain(b"\n".iter())
                .chain(self.certificate.iter())
                .copied(),
        )
    }
}

#[derive(Debug, Error)]
pub enum HostIdentityError {
    #[error("The hostname {0:?} cannot be expressed as a rust String")]
    HostnameNotString(OsString),
}

pub fn read(config: &Configuration) -> anyhow::Result<HostIdentity> {
    let hostname = gethostname()?
        .into_string()
        .map_err(HostIdentityError::HostnameNotString)?;
    let certificate = fs::read(&config.certificate)
        .with_context(|| format!("failed to read certificate at {:?}", config.key))?;
    let certificate_key = fs::read(&config.key)
        .with_context(|| format!("failed to read private key at {:?}", config.key))?;

    Ok(HostIdentity {
        hostname,
        certificate,
        certificate_key,
    })
}
