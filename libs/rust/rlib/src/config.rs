use std::{
    env::{self, VarError},
    fs,
    path::PathBuf,
    str::FromStr,
};

use serde::{Deserialize, de::DeserializeOwned};

use crate::sensitive::Sensitive;

#[derive(Debug, Deserialize)]
#[serde(untagged)]
pub enum SecretValue<T> {
    Literal(Sensitive<T>),
    File { path: PathBuf },
    Environment { env: String },
}

impl<T: FromStr + Clone> SecretValue<T> {
    pub fn read(&self) -> anyhow::Result<Sensitive<T>>
    where
        <T as FromStr>::Err: std::error::Error + Send + Sync + 'static,
    {
        match self {
            SecretValue::Literal(sensitive) => Ok(sensitive.clone()),
            SecretValue::File { path } => Ok(fs::read_to_string(path)?.parse()?),
            SecretValue::Environment { env } => Ok(env::var(env)?.parse()?),
        }
    }
}

pub fn load<T: DeserializeOwned>() -> anyhow::Result<T> {
    let path = match env::var("RAMONA_RED_CONFIG_PATH") {
        Ok(x) => x,
        Err(VarError::NotPresent) => env::var("RAMONA_CONFIG_PATH")?,
        Err(e) => return Err(e.into()),
    };

    Ok(subst::json::from_slice(&fs::read(path)?, &subst::Env)?)
}
