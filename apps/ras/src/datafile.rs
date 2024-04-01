use std::{collections::HashMap, path::PathBuf};

use serde::{Deserialize, Serialize};

pub trait DataFileReader {
    fn read(&self) -> DataFile;
    fn save(&self, data: DataFile);
}

pub struct DefaultDataFileReader {
    path: PathBuf,
}

impl DefaultDataFileReader {
    pub fn new(path: PathBuf) -> Self {
        Self { path }
    }
}

impl DataFileReader for DefaultDataFileReader {
    fn read(&self) -> DataFile {
        let contents = std::fs::read_to_string(&self.path).unwrap();

        if let Ok(datafile) = serde_json::from_str(&contents) {
            datafile
        } else if let Ok(todos) =
            serde_json::from_str::<HashMap<ratlib::todo::Id, ratlib::todo::Todo>>(&contents)
        {
            // FIXME Legacy data format - todos only. Remove this - we don't have the legacy data
            // format anywhere anymore.
            DataFile {
                todos,
                events: HashMap::new(),
            }
        } else {
            panic!("Failed to read the data file!");
        }
    }

    fn save(&self, data: DataFile) {
        std::fs::write(&self.path, serde_json::to_string_pretty(&data).unwrap()).unwrap();
    }
}

#[derive(Serialize, Deserialize)]
pub struct DataFile {
    pub todos: HashMap<ratlib::todo::Id, ratlib::todo::Todo>,
    #[serde(default)]
    pub events: HashMap<ratlib::calendar::event::Id, ratlib::calendar::event::Event>,
}
