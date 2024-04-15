use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
pub struct PostHerdMachine {
    pub current_closure: String,
}
