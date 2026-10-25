use std::{ffi::OsString, fs};

use crate::config::Configuration;
use anyhow::Context;
use nix::unistd::gethostname;
use rlib::{host_identity::HostIdentity, hosts::Hostname, sensitive::Sensitive};
use thiserror::Error;

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

    Ok(HostIdentity::new(
        Hostname::new(hostname),
        certificate,
        Sensitive::new(certificate_key),
    ))
}
