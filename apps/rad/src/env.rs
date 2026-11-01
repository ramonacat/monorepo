use std::{env, path::PathBuf};

use anyhow::Context;

const ENV_CONFIG_PATH: &str = "RAMONA_CONFIG_PATH";

pub fn config_path() -> anyhow::Result<PathBuf> {
    let raw_path =
        env::var(ENV_CONFIG_PATH).with_context(|| format!("{ENV_CONFIG_PATH} is not set"))?;

    let path: PathBuf = raw_path
        .parse()
        .with_context(|| format!("path {raw_path} from {ENV_CONFIG_PATH} is invalid"))?;

    Ok(path)
}
