#![deny(clippy::pedantic)]

use std::{fs::File, io::Write, path::PathBuf, time::Duration};

use clap::{Parser, Subcommand};
use colored::{Color, Colorize};
use petgraph::adj::NodeIndex;
use serde::{Deserialize, Serialize};
use store::Store;
use todo::Id;

use crate::todo::{Priority, Todo};

mod store;
mod todo;

#[derive(Subcommand)]
enum Command {
    Add {
        title: String,
        priority: String,
        estimate: u64,
        depends_on: Vec<usize>,
    },
    Done {
        id: usize,
    },
    Doing {
        id: usize,
    },
    Todo {
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
    SetEstimate {
        id: usize,
        estimate: u64,
    },
    List,
}

#[derive(Parser)]
struct Cli {
    #[command(subcommand)]
    command: Command,
}

impl From<Id> for NodeIndex<usize> {
    fn from(value: Id) -> Self {
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

    let mut todo_store = Store::new(data_path);

    match cli.command {
        Command::Add {
            title,
            priority,
            estimate,
            depends_on,
        } => {
            let id = todo_store
                .create(
                    title.clone(),
                    parse_priority(&priority),
                    Duration::from_secs(estimate * 60),
                    depends_on.iter().map(|x| Id(*x)).collect(),
                )
                .unwrap();

            println!("Inserted a new TODO with title \"{title}\" and ID {id}");
        }
        Command::List => {
            fn render_todo(todo: &Todo) -> String {
                let mut depends_string = "deps: ".to_string();
                for dependency_id in todo.depends_on() {
                    depends_string += &format!("{dependency_id} ");
                }

                format!(
                    "{:>10} {:>10}     {} {} {}",
                    todo.id().to_string().color(Color::BrightBlack),
                    todo.priority().to_string(),
                    todo.title(),
                    if todo.depends_on().is_empty() {
                        "".color(Color::Blue)
                    } else {
                        depends_string.color(Color::Blue)
                    },
                    format!("{}min", todo.estimate().as_secs() / 60).color(Color::BrightYellow)
                )
            }

            let doing = todo_store.find_doing();

            if !doing.is_empty() {
                println!("{}", "Doing: ".color(Color::Yellow).bold());

                for todo in doing {
                    let todo = render_todo(&todo);

                    println!("{todo}");
                }

                println!();
            }

            println!("{}", "Todo: ".color(Color::Red).bold());
            let ready_to_do = todo_store.find_ready_to_do();

            for todo in ready_to_do {
                let todo = render_todo(&todo);

                println!("{todo}");
            }
        }
        Command::Doing { id } => {
            todo_store.mark_as_doing(Id(id)).unwrap();
        }
        Command::Done { id } => {
            todo_store.mark_as_done(Id(id)).unwrap();
        }
        Command::Todo { id } => {
            todo_store.mark_as_todo(Id(id)).unwrap();
        }
        Command::AddDependency { id, dependency_ids } => {
            todo_store
                .add_dependency(Id(id), dependency_ids.into_iter().map(Id).collect())
                .unwrap();
        }
        Command::SetPriority { id, priority } => {
            todo_store
                .set_priority(Id(id), parse_priority(&priority))
                .unwrap();
        }
        Command::SetEstimate { id, estimate } => {
            todo_store
                .set_estimate(Id(id), Duration::from_secs(estimate * 60))
                .unwrap();
        }
    }
}
