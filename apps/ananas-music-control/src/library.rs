use std::path::{Path, PathBuf};

#[derive(Debug)]
pub struct Track {
    artist: String,
    title: String,
    album: String,
    path: PathBuf,
    number: u32, // TODO support multi-disc albums
}

impl Track {
    pub fn artist(&self) -> &str {
        &self.artist
    }

    pub fn title(&self) -> &str {
        &self.title
    }

    pub fn album(&self) -> &str {
        &self.album
    }

    pub fn path(&self) -> &Path {
        &self.path
    }
}

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

    pub fn list_tracks(&self, artist: &str, album: &str) -> Vec<Track> {
        let mut path = self.path.clone();
        path.push(artist);
        path.push(album);

        let mut files = vec![];
        for file in std::fs::read_dir(&path).unwrap() {
            let file = file.unwrap();

            if !file.metadata().unwrap().is_file() {
                continue;
            }

            let Some(extension) = file
                .path()
                .extension()
                .map(|x| x.to_string_lossy().to_string())
            else {
                continue;
            };

            // TODO consider supporting more extensions ;)
            if extension != "flac" {
                continue;
            }

            let name = file.file_name().to_string_lossy().to_string();

            if name.starts_with('.') {
                continue;
            }

            files.push(file.path());
        }

        let mut tracks: Vec<Track> = files
            .into_iter()
            .map(|filename| {
                let vorbis_comment =
                    flac::metadata::get_vorbis_comment(filename.to_string_lossy().as_ref());

                let mut album_artist = String::new();
                let mut album_title = String::new();
                let mut track_title = String::new();
                let mut number: u32 = 0;

                if let Ok(vorbis_comment) = vorbis_comment {
                    let comments = vorbis_comment.comments;

                    album_artist = comments
                        .get("ALBUMARTIST")
                        .or_else(|| comments.get("ARTIST"))
                        .map(|x| x.to_string())
                        .unwrap_or_else(|| "Unknown Artist".to_string());

                    album_title = comments
                        .get("ALBUM")
                        .map(|x| x.to_string())
                        .unwrap_or_else(|| "Unknown Album".to_string());

                    track_title =
                        comments
                            .get("TITLE")
                            .map(|x| x.to_string())
                            .unwrap_or_else(|| {
                                filename.file_name().unwrap().to_string_lossy().to_string()
                            });

                    number = comments
                        .get("TRACKNUMBER")
                        .map(|x| x.parse().unwrap_or(0))
                        .unwrap_or(0);
                }

                Track {
                    artist: album_artist,
                    title: track_title,
                    album: album_title,
                    path: filename.clone(),
                    number,
                }
            })
            .collect();

        tracks.sort_by(|x, y| y.number.cmp(&x.number));

        tracks
    }
}
