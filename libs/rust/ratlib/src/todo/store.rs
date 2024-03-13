use std::{collections::HashMap, ops::Add, path::PathBuf, time::Duration};

use chrono::{DateTime, NaiveTime, TimeDelta, TimeZone, Utc};
use chrono_tz::Europe::Berlin;
use thiserror::Error;

use crate::{
    datafile::DataFile,
    todo::{Id, Priority, Requirement, Status, Todo},
};

use super::IdGenerator;

pub struct Store {
    path: PathBuf,
}

#[derive(Debug, Error)]
pub enum Error {}

impl Store {
    pub fn new(path: PathBuf) -> Self {
        Self { path }
    }

    pub fn create(
        &mut self,
        title: String,
        priority: Priority,
        estimate: Duration,
        requirements: Vec<Requirement>,
    ) -> Id {
        let mut datafile = DataFile::open_path(&self.path);
        let mut id_generator =
            IdGenerator::new(datafile.todos.values().map(|x| x.id().0).max().unwrap_or(0));

        let id = id_generator.next();

        let new_todo = Todo::new(id, title, priority, requirements, estimate);
        datafile.todos.insert(id, new_todo);

        datafile.save(&self.path);

        id
    }

    // TODO: This should really be its own struct...
    fn evaluate_requirements(
        all_todos: &HashMap<Id, Todo>,
        requirements: &[Requirement],
        as_of: DateTime<Utc>,
    ) -> bool {
        for requirement in requirements {
            match requirement {
                Requirement::TodoDone(id) => {
                    if !all_todos
                        .get(id)
                        .is_some_and(|x| x.status() == Status::Done)
                    {
                        return false;
                    }
                }
                Requirement::AfterDate(when) => {
                    if as_of <= *when {
                        return false;
                    }
                }
            }
        }

        true
    }

    pub fn find_ready_to_do(&self) -> Vec<Todo> {
        let datafile = DataFile::open_path(&self.path);
        let mut todos_to_consider = datafile
            .todos
            .values()
            .filter(|v| v.status() == crate::todo::Status::Todo)
            .filter(|v| Self::evaluate_requirements(&datafile.todos, v.requirements(), Utc::now()))
            .cloned()
            .collect::<Vec<_>>();

        todos_to_consider.sort_by_key(|b| std::cmp::Reverse(b.priority()));

        todos_to_consider
    }

    pub fn find_becoming_valid_on(&self, day: chrono::prelude::NaiveDate) -> Vec<Todo> {
        let datafile = DataFile::open_path(&self.path);
        let mut todos_to_consider = datafile
            .todos
            .values()
            .filter(|v| v.status() == crate::todo::Status::Todo)
            .filter(|v| {
                Self::evaluate_requirements(
                    &datafile.todos,
                    v.requirements(),
                    Berlin.from_utc_datetime(
                        &day
                            .add(TimeDelta::try_days(1).unwrap())
                            .and_time(NaiveTime::from_num_seconds_from_midnight_opt(0, 0).unwrap())
                    ).to_utc()
                )
            })
            .filter(|v| {
                let mut should_display = false;

                for req in v.requirements() {
                    match req {
                        Requirement::TodoDone(_) => {}
                        Requirement::AfterDate(d) => {
                            if d.to_utc().date_naive() == day {
                                should_display = true;
                            }
                        }
                    }
                }

                should_display
            })
            .cloned()
            .collect::<Vec<_>>();

        todos_to_consider.sort_by_key(|b| std::cmp::Reverse(b.priority()));

        todos_to_consider
    }

    pub fn find_doing(&self) -> Vec<Todo> {
        let datafile = DataFile::open_path(&self.path);

        datafile
            .todos
            .into_values()
            .filter(|x| x.status() == Status::Doing)
            .collect()
    }

    pub fn find_by_id(&self, id: Id) -> Option<Todo> {
        let datafile = DataFile::open_path(&self.path);

        datafile.todos.get(&id).cloned()
    }

    pub fn save(&mut self, todo: Todo) {
        let mut datafile = DataFile::open_path(&self.path);

        datafile.todos.insert(todo.id(), todo);

        datafile.save(&self.path);
    }
}
