use std::{
    fs,
    path::{Path, PathBuf},
};

use anyhow::Context as _;

pub struct NixOsInfo {
    current_closure: PathBuf,
}

impl NixOsInfo {
    pub fn current_closure(&self) -> &Path {
        &self.current_closure
    }
}

const CURRENT_CLOSURE_PATH: &str = "/run/current-system";

pub fn read() -> anyhow::Result<NixOsInfo> {
    let current_closure = fs::canonicalize(CURRENT_CLOSURE_PATH)
        .with_context(|| format!("failed to read currect closure at {}", CURRENT_CLOSURE_PATH))?;

    Ok(NixOsInfo { current_closure })
}
