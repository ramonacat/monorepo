#![deny(clippy::pedantic)]

use std::{convert::Infallible, fs::File, io::Write, num::ParseIntError, path::PathBuf, time::Duration};

use chrono::{DateTime, Local, NaiveDate, NaiveDateTime, ParseError, TimeZone};
use chrono_tz::Europe::Berlin;
use chrono_tz::Tz;
use clap::{Parser, Subcommand};
use ratlib::{calendar, todo::{self, store::Store, Id, Priority, Requirement, Status}};
use regex::Regex;
use serde::{Deserialize, Serialize};
use thiserror::Error;

mod cli;

fn parse_priority(value: &str) -> Result<Priority, Infallible> {
        // todo prolly should like throw an error for weird values
        match value {
            "high" => Ok(Priority::High),
            "low" => Ok(Priority::Low),
            _ => Ok(Priority::Medium),
        }
}

// TODO: Actually hanlde errors...
fn parse_requirement(value: &str) -> Result<Requirement, Infallible> {
        let after_date =
            Regex::new(r"after\(([0-9]{4}\-[0-9]{2}\-[0-9]{2}(?: [0-9]{2}:[0-9]{2}:[0-9]{2})?)\)")
                .unwrap();

        if let Ok(id) = value.parse() {
            Ok(todo::Requirement::TodoDone(Id(id)))
        } else if let Some(captures) = after_date.captures(value) {
            let date =
                if let Ok(x) = NaiveDateTime::parse_from_str(&captures[1], "%Y-%m-%d %H:%M:%S") {
                    x
                } else if let Ok(x) = NaiveDate::parse_from_str(&captures[1], "%Y-%m-%d") {
                    NaiveDateTime::from(x)
                } else {
                    panic!("Invalid date/time");
                };
            let local_now = Local.from_local_datetime(&date).unwrap();

            Ok(todo::Requirement::AfterDate(local_now.into()))
        } else {
            panic!("Failed to parse: {value}");
        }
}

fn parse_minutes(minutes: &str) -> Result<Duration, ParseIntError> {
    let minutes: u64 = minutes.parse()?;

    Ok(Duration::from_secs(minutes * 60))
}

fn parse_id(id: &str) -> Result<Id, ParseIntError> {
    let id = id.parse()?;

    Ok(Id(id))
}

#[derive(Error, Debug)]
enum TimespecError {
    #[error("parse error: {0}")]
    Parse(#[from] ParseError),
}

fn parse_timespec(timespec: &str) -> Result<DateTime<Tz>, TimespecError> {
    let result = NaiveDateTime::parse_from_str(timespec, "%Y-%m-%d %H:%M:%S")
        .or_else(|_| NaiveDateTime::parse_from_str(timespec, "%Y-%m-%d %H:%M"))?;

    // todo pull the default TZ from the OS
    Ok(Berlin.from_local_datetime(&result).unwrap())
}

#[derive(Subcommand)]
enum CalendarAction {
    Today,
    Add {
        #[arg(value_parser=parse_timespec)]
        when: DateTime<Tz>,
        #[arg(value_parser=parse_minutes)]
        duration: Duration,
        title: String,
    },
}

#[derive(Subcommand)]
enum Command {
    Add {
        title: String,
        #[arg(value_parser=parse_priority)]
        priority: Priority,
        #[arg(value_parser=parse_minutes)]
        estimate: Duration,
        #[arg(value_parser=parse_requirement)]
        requirements: Vec<Requirement>,
    },
    Done {
        #[arg(value_parser=parse_id)]
        id: Id,
    },
    Doing {
        #[arg(value_parser=parse_id)]
        id: Id,
    },
    Todo {
        #[arg(value_parser=parse_id)]
        id: Id,
    },
    Edit {
        #[arg(value_parser=parse_id)]
        id: Id,
        #[arg(short, long, value_parser = parse_requirement)]
        add_requirements: Option<Vec<Requirement>>,
        #[arg(short = 'p', long, value_parser = parse_priority)]
        set_priority: Option<Priority>,
        #[arg(short = 'e', long, value_parser = parse_minutes)]
        set_estimate: Option<Duration>,
        #[arg(short = 't', long)]
        set_title: Option<String>,
    },
    List,
    Calendar {
        #[command(subcommand)]
        action: CalendarAction,
    },
}

#[derive(Parser)]
struct Cli {
    #[command(subcommand)]
    command: Command,
}

#[derive(Serialize, Deserialize)]
struct Configuration {
    storage_path: PathBuf,
}

fn read_configuration() -> Configuration {
    let mut xdg_config_directory: PathBuf = std::env::var("XDG_CONFIG_HOME")
        .map(PathBuf::from)
        .or_else(|_| {
            let mut path = PathBuf::from(std::env::var("HOME")?);
            path.push(".config");
            Ok::<PathBuf, std::env::VarError>(path)
        })
        .unwrap();

    xdg_config_directory.push("rat/");

    std::fs::create_dir_all(&xdg_config_directory).unwrap();

    let mut config_path = xdg_config_directory.clone();
    config_path.push("config.json");

    let mut xdg_data_directory: PathBuf = std::env::var("XDG_DATA_HOME")
        .map(PathBuf::from)
        .or_else(|_| {
            let mut path = PathBuf::from(std::env::var("HOME")?);
            path.push(".local/share");

            Ok::<PathBuf, std::env::VarError>(path)
        })
        .unwrap();

    xdg_data_directory.push("rat/");

    std::fs::create_dir_all(&xdg_data_directory).unwrap();

    let mut default_data_path = xdg_data_directory.clone();
    default_data_path.push("todos.json");

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

    serde_json::from_str(&configuration).expect("Failed to parse the configuration file")
}

fn main() {
    let cli = Cli::parse();
    let configuration = read_configuration();
    let data_path = configuration.storage_path;

    if !data_path.exists() {
        let mut data_file = File::create(&data_path).expect("Data file could not be created");
        data_file
            .write_all(b"{}")
            .expect("Failed to write to the data file");
    }

    let mut todo_store = Store::new(data_path.clone());
    let event_store = calendar::store::Store::new(data_path);

    match cli.command {
        Command::Add {
            title,
            priority,
            estimate,
            requirements,
        } => {
            cli::add::execute(&mut todo_store, &title, priority, estimate, requirements);
        }
        Command::List => {
            cli::list::execute(&todo_store);
        }
        Command::Doing { id } => {
            cli::state_transition::execute(&mut todo_store, id, Status::Doing);
        }
        Command::Done { id } => {
            cli::state_transition::execute(&mut todo_store, id, Status::Done);
        }
        Command::Todo { id } => {
            cli::state_transition::execute(&mut todo_store, id, Status::Todo);
        }
        Command::Edit {
            id,
            add_requirements,
            set_priority,
            set_estimate,
            set_title,
        } => {
            cli::edit::execute(
                &mut todo_store,
                id,
                add_requirements,
                set_priority,
                set_estimate,
                set_title,
            );
        }
        Command::Calendar { action } => {
            cli::calendar::execute(&event_store, &todo_store, action);
        }
    }
}
