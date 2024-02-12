use std::{fs::File, io::Write, path::PathBuf};

use clap::{Parser, Subcommand};
use colored::{Color, Colorize};
use petgraph::adj::NodeIndex;
use serde::{Deserialize, Serialize};
use store::TodoStore;
use todo::TodoId;

use crate::todo::Priority;

mod store;
mod todo;

#[derive(Subcommand)]
enum Command {
    Add {
        title: String,
        priority: String,
        depends_on: Vec<usize>,
    },
    Done {
        id: usize,
    },
    AddDependency {
        id: usize,
        dependency_ids: Vec<usize>,
    },
    SetPriority {
        id: usize,
        priority: String,
    },
    List,
}

#[derive(Parser)]
struct Cli {
    #[command(subcommand)]
    command: Command,
}

impl From<TodoId> for NodeIndex<usize> {
    fn from(value: TodoId) -> Self {
        value.0
    }
}

#[derive(Serialize, Deserialize)]
struct Configuration {
    storage_path: PathBuf,
}

fn parse_priority(priority: &str) -> Priority {
    // todo prolly should like throw an error for weird values
    match priority {
        "high" => Priority::High,
        "low" => Priority::Low,
        _ => Priority::Medium,
    }
}

fn main() {
    let cli = Cli::parse();
    let xdg_directories = xdg::BaseDirectories::with_prefix("rat").unwrap();
    let config_path = xdg_directories
        .place_config_file("config.json")
        .expect("Cannot find configuration file destination");
    let default_data_path = xdg_directories
        .place_data_file("todos.json")
        .expect("Failed to place the data file");

    if !config_path.exists() {
        let mut config_file =
            File::create(&config_path).expect("Failed to create the configuration file");
        let configuration = serde_json::to_string_pretty(&Configuration {
            storage_path: default_data_path.clone(),
        })
        .expect("Failed to serialize the configuration");
        config_file
            .write_all(configuration.as_bytes())
            .expect("Failed to write the configuration file");
    }

    let configuration =
        std::fs::read_to_string(config_path).expect("Failed to read the configuration file");
    let configuration: Configuration =
        serde_json::from_str(&configuration).expect("Failed to parse the configuration file");
    let data_path = configuration.storage_path;

    if !data_path.exists() {
        let mut data_file = File::create(&data_path).expect("Data file could not be created");
        data_file
            .write_all(b"{}")
            .expect("Failed to write to the data file");
    }

    let mut todo_store = TodoStore::new(data_path);

    match cli.command {
        Command::Add {
            title,
            priority,
            depends_on,
        } => {
            let id = todo_store
                .create(
                    title.clone(),
                    parse_priority(&priority),
                    depends_on.iter().map(|x| TodoId(*x)).collect(),
                )
                .unwrap();

            println!("Inserted a new TODO with title \"{title}\" and ID {id}");
        }
        Command::List => {
            let ready_to_do = todo_store.find_ready_to_do();

            for node in ready_to_do.iter() {
                let mut depends_string = "deps: ".to_string();
                for dependency_id in node.depends_on().iter() {
                    depends_string += &format!("{} ", dependency_id);
                }

                let todo_descriptor = format!(
                    "{:>10} {:>10}     {} {}",
                    node.id().to_string().color(Color::BrightBlack),
                    node.priority().to_string(),
                    node.title(),
                    depends_string.color(Color::Blue)
                );
                if node.done() {
                    println!("{}", todo_descriptor.strikethrough());
                } else {
                    println!("{}", todo_descriptor);
                }
            }
        }
        Command::Done { id } => {
            todo_store.mark_as_done(TodoId(id)).unwrap();
        }
        Command::AddDependency { id, dependency_ids } => {
            todo_store
                .add_dependency(TodoId(id), dependency_ids.into_iter().map(TodoId).collect())
                .unwrap();
        }
        Command::SetPriority { id, priority } => {
            todo_store
                .set_priority(TodoId(id), parse_priority(&priority))
                .unwrap();
        }
    }
}
