use std::{collections::HashMap, path::Path};

use serde::{Deserialize, Serialize};

use crate::todo::{Id, Todo};

#[derive(Serialize, Deserialize)]
pub struct DataFile {
    pub todos: HashMap<Id, Todo>,
}

impl DataFile {
    pub fn open_path(path: &Path) -> DataFile {
        let contents = std::fs::read_to_string(path).unwrap();

        if let Ok(datafile) = serde_json::from_str(&contents) {
            datafile
        } else if let Ok(todos) = serde_json::from_str::<HashMap<Id, Todo>>(&contents) {
            DataFile { todos }
        } else {
            panic!("Failed to read the data file!");
        }
    }

    pub fn save(self, path: &Path) {
        std::fs::write(path, serde_json::to_string_pretty(&self).unwrap()).unwrap();
    }
}
