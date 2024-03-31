use thiserror::Error;

#[derive(Error, Debug)]
pub enum Error {
    #[error("IO: {0}")]
    Io(#[from] std::io::Error),
}

pub fn read(name: impl Into<String>) -> Result<String, Error> {
    Ok(std::fs::read_to_string(format!(
        "/var/run/agenix/{}",
        name.into()
    ))?)
}
