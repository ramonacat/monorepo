use std::{collections::HashMap, ops::Add, sync::Arc, time::Duration};

use crate::datafile::DataFileReader;
use chrono::{DateTime, NaiveTime, TimeDelta, TimeZone, Utc};
use chrono_tz::{Europe::Berlin, Tz};
use ratlib::todo::{Id, IdGenerator, Priority, Requirement, Status, Todo};
use thiserror::Error;

pub struct Store {
    datafile_reader: Arc<dyn DataFileReader + Send + Sync>,
}

#[derive(Debug, Error)]
pub enum Error {}

impl Store {
    pub fn new(datafile_reader: Arc<dyn DataFileReader + Send + Sync>) -> Self {
        Self { datafile_reader }
    }

    pub fn create(
        &mut self,
        title: String,
        priority: Priority,
        estimate: Duration,
        requirements: Vec<Requirement>,
        deadline: Option<DateTime<Tz>>,
    ) -> Id {
        let mut datafile = self.datafile_reader.read();
        let mut id_generator =
            IdGenerator::new(datafile.todos.values().map(|x| x.id().0).max().unwrap_or(0));

        let id = id_generator.next();

        let new_todo = Todo::new(id, title, priority, requirements, estimate, deadline);
        datafile.todos.insert(id, new_todo);

        self.datafile_reader.save(datafile);

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
        let datafile = self.datafile_reader.read();
        let mut todos_to_consider = datafile
            .todos
            .values()
            .filter(|v| v.status() == Status::Todo)
            .filter(|v| Self::evaluate_requirements(&datafile.todos, v.requirements(), Utc::now()))
            .cloned()
            .collect::<Vec<_>>();

        todos_to_consider.sort_by_key(|b| std::cmp::Reverse(b.priority()));

        todos_to_consider
    }

    pub fn find_becoming_valid_on(&self, day: chrono::prelude::NaiveDate) -> Vec<Todo> {
        let datafile = self.datafile_reader.read();
        let mut todos_to_consider =
            datafile
                .todos
                .values()
                .filter(|v| v.status() == Status::Todo)
                .filter(|v| {
                    Self::evaluate_requirements(
                        &datafile.todos,
                        v.requirements(),
                        Berlin
                            .from_utc_datetime(&day.add(TimeDelta::try_days(1).unwrap()).and_time(
                                NaiveTime::from_num_seconds_from_midnight_opt(0, 0).unwrap(),
                            ))
                            .to_utc(),
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
        let datafile = self.datafile_reader.read();

        datafile
            .todos
            .into_values()
            .filter(|x| x.status() == Status::Doing)
            .collect()
    }

    pub fn find_around_deadline(&self) -> Vec<Todo> {
        let datafile = self.datafile_reader.read();

        datafile
            .todos
            .into_values()
            .filter(|x| x.status() != Status::Done)
            .filter(|x| match x.deadline() {
                Some(deadline) => {
                    deadline.signed_duration_since(Utc::now()).abs().num_days() <= 1
                        || deadline > Utc::now()
                }
                None => false,
            })
            .collect()
    }

    pub fn find_by_id(&self, id: Id) -> Option<Todo> {
        let datafile = self.datafile_reader.read();

        datafile.todos.get(&id).cloned()
    }

    pub fn save(&mut self, todo: Todo) {
        let mut datafile = self.datafile_reader.read();

        datafile.todos.insert(todo.id(), todo);

        self.datafile_reader.save(datafile);
    }
}

#[cfg(test)]
mod tests {
    use std::{
        sync::{Arc, Mutex},
        time::Duration,
    };

    use chrono::{NaiveDate, TimeZone, Utc};
    use ratlib::{
        calendar::event::Event,
        todo::{Id, Priority, Requirement, Todo},
    };

    use crate::{
        datafile::{DataFile, DataFileReader},
        todo::store::Store,
    };

    struct MockStore(pub Mutex<(Vec<Todo>, Vec<Event>)>);

    impl DataFileReader for MockStore {
        fn read(&self) -> crate::datafile::DataFile {
            let guard = self.0.lock().unwrap();
            let (todos, events) = (guard.0.clone(), guard.1.clone());

            DataFile {
                todos: todos.into_iter().map(|x| (x.id(), x)).collect(),
                events: events.into_iter().map(|x| (x.id(), x)).collect(),
            }
        }

        fn save(&self, data: crate::datafile::DataFile) {
            let mut guard = self.0.lock().unwrap();

            *guard = (
                data.todos.into_values().collect(),
                data.events.into_values().collect(),
            );
        }
    }

    #[test]
    pub fn can_create() {
        let data_file_reader = MockStore(Mutex::new((vec![], vec![])));

        let mut store = Store::new(Arc::new(data_file_reader));
        let id = store.create(
            "This is a todo".to_string(),
            Priority::Low,
            Duration::from_secs(15),
            vec![],
            None,
        );

        assert_eq!(
            Todo::new(
                id,
                "This is a todo".to_string(),
                Priority::Low,
                vec![],
                Duration::from_secs(15),
                None
            ),
            store.find_by_id(id).unwrap()
        );
    }

    #[test]
    pub fn can_find_by_id() {
        let findme = Todo::new(
            Id(2),
            "asdf".to_string(),
            ratlib::todo::Priority::Medium,
            vec![],
            Duration::from_secs(1024),
            None,
        );
        let data_file_reader = MockStore(Mutex::new((
            vec![
                Todo::new(
                    Id(1),
                    "asdf".to_string(),
                    ratlib::todo::Priority::Medium,
                    vec![],
                    Duration::from_secs(1024),
                    None,
                ),
                findme.clone(),
            ],
            vec![],
        )));

        let store = Store::new(Arc::new(data_file_reader));

        assert_eq!(Some(findme), store.find_by_id(Id(2)));
    }

    #[test]
    pub fn test_can_find_ready_to_do() {
        let findme = Todo::new(
            Id(1),
            "aaa".to_string(),
            ratlib::todo::Priority::High,
            vec![],
            Duration::from_secs(120),
            None,
        );
        let data_file_reader = MockStore(Mutex::new((
            vec![
                findme.clone(),
                Todo::new(
                    Id(2),
                    "basdf".to_string(),
                    Priority::High,
                    vec![Requirement::TodoDone(Id(1))],
                    Duration::from_secs(15),
                    None,
                ),
            ],
            vec![],
        )));

        let store = Store::new(Arc::new(data_file_reader));

        assert_eq!(vec![findme], store.find_ready_to_do());
    }

    #[test]
    pub fn can_find_becoming_valid_on() {
        let todo = Todo::new(
            Id(1234),
            "aaa".to_string(),
            Priority::High,
            vec![Requirement::AfterDate(
                Utc.with_ymd_and_hms(2022, 1, 1, 16, 0, 0).unwrap(),
            )],
            Duration::from_secs(12),
            None,
        );

        let data_file_reader = MockStore(Mutex::new((
            vec![
                todo.clone(),
                Todo::new(
                    Id(2),
                    "basdf".to_string(),
                    Priority::High,
                    vec![],
                    Duration::from_secs(15),
                    None,
                ),
            ],
            vec![],
        )));

        let store = Store::new(Arc::new(data_file_reader));

        let becoming_valid =
            store.find_becoming_valid_on(NaiveDate::from_ymd_opt(2022, 1, 1).unwrap());

        assert_eq!(vec![todo], becoming_valid);
    }

    #[test]
    pub fn can_find_doing() {
        let mut todo = Todo::new(
            Id(1234),
            "aaa".to_string(),
            Priority::High,
            vec![],
            Duration::from_secs(12),
            None,
        );
        todo.transition_to(ratlib::todo::Status::Doing);

        let data_file_reader = MockStore(Mutex::new((
            vec![
                todo.clone(),
                Todo::new(
                    Id(2),
                    "basdf".to_string(),
                    Priority::High,
                    vec![],
                    Duration::from_secs(15),
                    None,
                ),
            ],
            vec![],
        )));

        let store = Store::new(Arc::new(data_file_reader));

        let doing = store.find_doing();

        assert_eq!(vec![todo], doing);
    }

    #[test]
    pub fn can_save() {
        let todo = Todo::new(
            Id(1234),
            "aaa".to_string(),
            Priority::High,
            vec![],
            Duration::from_secs(12),
            None,
        );

        let data = Mutex::new((vec![todo.clone()], vec![]));
        let data_file_reader = Arc::new(MockStore(data));

        let mut store = Store::new(data_file_reader.clone());
        store.save(todo.clone());

        let store = Store::new(data_file_reader);
        assert_eq!(vec![todo], store.find_ready_to_do());
    }
}
