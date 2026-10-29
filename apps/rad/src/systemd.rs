use std::{collections::HashMap, path::PathBuf, process::Stdio};
use tokio::{fs, process::Command};
use tracing::{debug, info};

use crate::io::{UpdateResult, update_if_changed};

const NETWORK_UNITS_PATH: &str = "/etc/systemd/network/";
const NETWORK_UNIT_PREFIX: &str = "22-ramona-";

#[derive(Debug, thiserror::Error)]
pub enum Error {
    #[error("io: {0}")]
    Io(#[from] std::io::Error),
    #[error("file update: {0}")]
    FileUpdate(#[from] crate::io::Error),
}

pub struct NetworkUnits {}

impl NetworkUnits {
    pub async fn replace_category(
        &self,
        category_name: &str,
        units: HashMap<String, String>,
    ) -> Result<UpdateResult, Error> {
        info!(?category_name, ?units, "replacing network units");

        let existing_units = self.find_existing().await?;

        info!(?existing_units, "found existing units");

        let mut changed = false;

        for unit_path in existing_units {
            let file_name = unit_path.file_name().unwrap().to_string_lossy();

            let full_prefix = format!("{NETWORK_UNIT_PREFIX}{category_name}-");

            if !file_name.starts_with(&full_prefix) {
                debug!(?unit_path, ?file_name, "not in category, skipping");
                continue;
            }

            let new_unit_contents = units.get(&file_name.replace(&full_prefix, ""));
            if let Some(contents) = new_unit_contents {
                if update_if_changed(&unit_path, contents).await? == UpdateResult::Changed {
                    info!(?unit_path, ?contents, "unit updated");
                    changed = true;
                }
            } else {
                fs::remove_file(&unit_path).await?;
                info!(?unit_path, "unit deleted");

                changed = true;
                continue;
            }
        }

        for (name, unit) in units {
            let path = PathBuf::from(NETWORK_UNITS_PATH)
                .join(format!("{NETWORK_UNIT_PREFIX}{category_name}-{name}"));
            debug!(?path, "checking path");

            if path.exists() {
                debug!(?path, ?name, ?unit, "unit already exists");

                continue;
            }

            info!(?path, name, unit, "creating unit");

            update_if_changed(path, &unit).await?;
            changed = true;
        }

        if changed {
            let reload = Command::new("networkctl")
                .arg("reload")
                .stdout(Stdio::piped())
                .stderr(Stdio::piped())
                .spawn()?;
            let reload_result = reload.wait_with_output().await?;

            info!(?reload_result, "networkd reloaded");
        }

        Ok(if changed {
            UpdateResult::Changed
        } else {
            UpdateResult::NotChanged
        })
    }

    async fn find_existing(&self) -> Result<Vec<PathBuf>, Error> {
        let mut reader = fs::read_dir(NETWORK_UNITS_PATH).await?;

        let mut paths = vec![];

        while let Some(entry) = reader.next_entry().await? {
            if !entry.file_type().await?.is_file() {
                continue;
            }

            if !entry
                .file_name()
                .to_string_lossy()
                .starts_with(NETWORK_UNIT_PREFIX)
            {
                continue;
            }

            paths.push(entry.path());
        }

        Ok(paths)
    }

    pub(crate) fn new() -> Self {
        Self {}
    }
}
