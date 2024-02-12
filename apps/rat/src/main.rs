use std::{collections::HashMap, fs::File, io::Write, path::PathBuf, process::exit};

use clap::{Parser, Subcommand};
use colored::{Color, Colorize};
use petgraph::{adj::NodeIndex, algo::toposort, graph::DiGraph};
use serde::{Deserialize, Serialize};
use todo::{IdGenerator, Todo, TodoId};

use crate::todo::Priority;

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

struct TodoStore {
    path: PathBuf,
}

impl TodoStore {
    pub fn new(path: PathBuf) -> Self {
        Self { path }
    }

    fn read(&self) -> HashMap<TodoId, Todo> {
        let raw_data = std::fs::read_to_string(&self.path).unwrap();
        serde_json::from_str(&raw_data).unwrap()
    }

    fn write(&mut self, todos: HashMap<TodoId, Todo>) {
        let serialized_data = serde_json::to_string_pretty(&todos).unwrap();

        std::fs::write(&self.path, serialized_data).unwrap();
    }
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

    let mut todos: HashMap<TodoId, Todo> = todo_store.read();
    let mut id_generator = IdGenerator::new(todos.keys().map(|k| k.0).max().unwrap_or(0));

    match cli.command {
        Command::Add {
            title,
            depends_on,
            priority,
        } => {
            let id = id_generator.next();
            let depends_on: Vec<_> = depends_on.into_iter().map(TodoId).collect();

            for dependency_id in &depends_on {
                if !todos.contains_key(dependency_id) {
                    println!("Incorrect dependency - no note with ID: {dependency_id:?}");
                    exit(1);
                }
            }

            todos.insert(
                id,
                Todo::new(id, title.clone(), parse_priority(&priority), depends_on),
            );

            println!("Inserted a new TODO with title \"{title}\" and ID {id}");
        }
        Command::List => {
            let mut graph = DiGraph::<TodoId, ()>::new();
            let mut todos_to_node_ids = HashMap::new();

            for (_, todo) in todos.iter() {
                let node_id = graph.add_node(todo.id());
                todos_to_node_ids.insert(todo.id(), node_id);
            }

            for (_, todo) in todos.iter() {
                for r in todo.depends_on().iter() {
                    graph.add_edge(todos_to_node_ids[r], todos_to_node_ids[&todo.id()], ());
                }
            }

            let toposorted = toposort(&graph, None);
            match toposorted {
                Ok(sorted) => {
                    let partitions = sorted
                        .iter()
                        .map(|idx| &todos[&graph[*idx]])
                        .partition::<Vec<&Todo>, _>(|t| !t.done());
                    for node in partitions.0.iter().chain(partitions.1.iter()) {
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
                Err(cycle) => {
                    println!("{:?}", cycle);
                }
            }
        }
        Command::Done { id } => {
            if let Some(todo) = todos.get_mut(&TodoId(id)) {
                todo.mark_done();
            } else {
                println!("There's no todo with ID {id}");
            }
        }
        Command::AddDependency { id, dependency_ids } => {
            if let Some(todo) = todos.get_mut(&TodoId(id)) {
                for dependency_id in dependency_ids {
                    todo.add_dependency(TodoId(dependency_id));
                }
            } else {
                println!("There's no todo with ID {id}");
            }
        }
        Command::SetPriority { id, priority } => {
            if let Some(todo) = todos.get_mut(&TodoId(id)) {
                todo.set_priority(parse_priority(&priority));
            } else {
                println!("There's no todo with ID {id}");
            }
        }
    }

    todo_store.write(todos);
}
