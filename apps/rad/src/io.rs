use anyhow::Context as _;
use std::fs;
use std::io::Read as _;
use std::io::Seek as _;
use std::io::SeekFrom;
use std::io::Write as _;
use std::path::Path;

#[derive(Debug, PartialEq, Eq)]
pub enum UpdateResult {
    Changed,
    NotChanged,
}

// TODO make async?
pub fn update_if_changed(path: impl AsRef<Path>, contents: &str) -> anyhow::Result<UpdateResult> {
    let path: &Path = path.as_ref();

    match fs::create_dir_all(path.parent().unwrap()) {
        Ok(()) => {}
        Err(e) if e.kind() == std::io::ErrorKind::AlreadyExists => {}
        Err(e) => {
            return Err(e).with_context(|| format!("creating {:?} for {path:?}", path.parent()));
        }
    }

    let mut file = fs::OpenOptions::new()
        .read(true)
        .write(true)
        .create(true)
        .truncate(false)
        .open(path)
        .with_context(|| format!("creating {path:?}"))?;
    let mut current_contents = String::new();
    file.read_to_string(&mut current_contents)?;

    if contents == current_contents {
        return Ok(UpdateResult::NotChanged);
    }

    file.set_len(0)?;
    file.seek(SeekFrom::Start(0))?;
    file.write_all(contents.as_bytes())?;

    Ok(UpdateResult::Changed)
}
