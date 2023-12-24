use std::path::{Path, PathBuf};

pub struct Library {
    path: PathBuf,
}

impl Library {
    pub fn new(path: PathBuf) -> Self {
        Self { path }
    }

    fn list_subdirectories(&self, path: &Path) -> Vec<String> {
        let mut artists = vec![];

        for subdirectory in std::fs::read_dir(path).unwrap() {
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

    pub fn list_artists(&self) -> Vec<String> {
        self.list_subdirectories(&self.path)
    }

    pub fn list_albums(&self, artist: &str) -> Vec<String> {
        let mut path = self.path.clone();
        path.push(artist);

        self.list_subdirectories(&path)
    }

    pub fn list_tracks(&self, artist: &str, album: &str) -> Vec<PathBuf> {
        let mut path = self.path.clone();
        path.push(artist);
        path.push(album);

        let mut files = vec![];
        for file in std::fs::read_dir(&path).unwrap() {
            let file = file.unwrap();

            if !file.metadata().unwrap().is_file() {
                continue;
            }

            let name = file.file_name().to_string_lossy().to_string();

            if name.starts_with('.') {
                continue;
            }

            files.push(file.path());
        }

        files.sort();

        files
    }
}
