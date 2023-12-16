use std::path::PathBuf;

pub struct Library {
    path: PathBuf,
}

impl Library {
    pub fn new(path: PathBuf) -> Self {
        Self { path }
    }

    pub fn list_artists(&self) -> Vec<String> {
        let mut artists = vec![];

        for subdirectory in std::fs::read_dir(&self.path).unwrap() {
            let subdirectory = subdirectory.unwrap();

            if !subdirectory.metadata().unwrap().is_dir() {
                continue;
            }

            let name = subdirectory.file_name().to_string_lossy().to_string();

            if name.starts_with('.') {
                continue;
            }

            artists.push(name);
        }

        artists
    }
}
