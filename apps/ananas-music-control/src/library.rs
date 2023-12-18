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

    pub fn list_albums(&self, artist: &str) -> Vec<String>{
        let mut albums = vec![];

        let mut path = self.path.clone();
        path.push(artist);

        for subdirectory in std::fs::read_dir(&path).unwrap() {
            let subdirectory = subdirectory.unwrap();

            if !subdirectory.metadata().unwrap().is_dir() {
                continue;
            }

            let name = subdirectory.file_name().to_string_lossy().to_string();

            if name.starts_with('.') {
                continue;
            }

            albums.push(name);
        }

        albums
    }
}
