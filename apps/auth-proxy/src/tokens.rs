use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct TokenQuery {
    pub rtoken: String,
}
