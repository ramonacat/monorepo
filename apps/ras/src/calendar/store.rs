use std::{path::PathBuf, time::Duration};

use chrono::{DateTime, TimeZone};
use chrono_tz::{Europe::Berlin, Tz};
use ratlib::calendar::event::{Event, Id};

use crate::datafile::DataFile;

pub struct Store {
    path: PathBuf,
}

impl Store {
    pub fn new(path: PathBuf) -> Self {
        Self { path }
    }

    pub fn create(&self, start: DateTime<Tz>, duration: Duration, title: String) -> Id {
        let mut datafile = DataFile::open_path(&self.path);

        let id = Id(datafile.events.keys().map(|x| x.0).min().unwrap_or(0) + 1);

        datafile
            .events
            .insert(id, Event::new(id, start, duration, title));

        datafile.save(&self.path);

        id
    }

    pub fn find_by_date(&self, day: chrono::prelude::NaiveDate) -> Vec<Event> {
        let datafile = DataFile::open_path(&self.path);
        let mut today: Vec<_> = datafile
            .events
            .into_values()
            .filter(|x| {
                Berlin
                    .from_utc_datetime(&x.start().to_utc().naive_utc())
                    .date_naive()
                    == day
            })
            .collect();

        today.sort_by_key(Event::start);
        today
    }
}
