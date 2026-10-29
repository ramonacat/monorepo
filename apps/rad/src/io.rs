use std::io::SeekFrom;
use std::path::Path;
use tokio::fs;
use tokio::io::AsyncReadExt as _;
use tokio::io::AsyncSeekExt as _;
use tokio::io::AsyncWriteExt as _;

#[derive(Debug, PartialEq, Eq)]
pub enum UpdateResult {
    Changed,
    NotChanged,
}

#[derive(Debug, thiserror::Error)]
pub enum Error {
    #[error("cannot create parent directory: {0}")]
    CreateParentDirectory(std::io::Error),
    #[error("cannot open file: {0}")]
    OpenFile(std::io::Error),
    #[error("read file: {0}")]
    ReadFile(std::io::Error),
    #[error("update file: {0}")]
    UpdateFile(std::io::Error),
}

pub async fn update_if_changed(
    path: impl AsRef<Path>,
    contents: &str,
) -> Result<UpdateResult, Error> {
    let path: &Path = path.as_ref();

    match fs::create_dir_all(path.parent().unwrap()).await {
        Ok(()) => {}
        Err(e) if e.kind() == std::io::ErrorKind::AlreadyExists => {}
        Err(e) => {
            return Err(Error::CreateParentDirectory(e));
        }
    }

    let mut file = fs::OpenOptions::new()
        .read(true)
        .write(true)
        .create(true)
        .truncate(false)
        .open(path)
        .await
        .map_err(Error::OpenFile)?;
    let mut current_contents = String::new();
    file.read_to_string(&mut current_contents)
        .await
        .map_err(Error::ReadFile)?;

    if contents == current_contents {
        return Ok(UpdateResult::NotChanged);
    }

    file.set_len(0).await.map_err(Error::UpdateFile)?;
    file.seek(SeekFrom::Start(0))
        .await
        .map_err(Error::UpdateFile)?;
    file.write_all(contents.as_bytes())
        .await
        .map_err(Error::UpdateFile)?;

    Ok(UpdateResult::Changed)
}
