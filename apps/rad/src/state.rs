use std::{
    collections::HashMap,
    fs,
    io::{self, Seek},
    path::PathBuf,
};

use serde::{Deserialize, Serialize};
use thiserror::Error;

#[derive(Debug, Deserialize, Serialize, Default)]
pub struct State {
    pub tunnel_ips: HashMap<uuid::Uuid, String>,
}

#[derive(Debug, Error)]
pub enum StateManagerError<T> {
    #[error("user: {0}")]
    User(T),

    #[error("io: {0}")]
    Io(#[from] io::Error),

    #[error("serde_json: {0}")]
    SerdeJson(#[from] serde_json::Error),
}

pub struct StateManager {
    path: PathBuf,
}

impl StateManager {
    pub fn new(path: impl Into<PathBuf>) -> Self {
        Self { path: path.into() }
    }

    pub async fn with_async<T, E>(
        &self,
        callback: impl AsyncFnOnce(&mut State) -> Result<T, E>,
    ) -> Result<T, StateManagerError<E>> {
        let mut state_file = fs::OpenOptions::new()
            .read(true)
            .write(true)
            .truncate(false)
            .create(true)
            .open(&self.path)?;
        state_file.lock()?;

        let mut state: State = match serde_json::from_reader(&state_file) {
            Ok(state) => state,
            Err(err) if err.is_eof() && err.line() == 1 && err.column() == 0 => State::default(),
            Err(e) => return Err(e.into()),
        };

        let result = match callback(&mut state).await {
            Ok(o) => Ok(o),
            Err(e) => Err(StateManagerError::User(e)),
        };

        state_file.set_len(0)?;
        state_file.seek(io::SeekFrom::Start(0))?;
        serde_json::to_writer_pretty(&state_file, &state)?;
        state_file.unlock()?;

        result
    }
}
