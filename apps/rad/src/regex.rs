use regex::Regex;
use serde::{Deserialize, Deserializer};

pub fn deserialize<'de, D: Deserializer<'de>>(de: D) -> Result<Regex, D::Error> {
    let raw = String::deserialize(de)?;

    Regex::new(&raw).map_err(serde::de::Error::custom)
}
