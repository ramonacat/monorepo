use std::{env, path::PathBuf};

use anyhow::Context;

const ENV_CONFIG_PATH: &str = "RAMONA_CONFIG_PATH";

pub fn config_path() -> anyhow::Result<PathBuf> {
    let raw_path =
        env::var(ENV_CONFIG_PATH).with_context(|| format!("{} is not set", ENV_CONFIG_PATH))?;

    let path: PathBuf = raw_path
        .parse()
        .with_context(|| format!("path {} from {} is invalid", raw_path, ENV_CONFIG_PATH))?;

    Ok(path)
}
