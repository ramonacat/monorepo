use std::{sync::Arc, time::Duration};

use chrono::{DateTime, TimeZone};
use chrono_tz::{Europe::Berlin, Tz};
use ratlib::calendar::event::{Event, Id};

use crate::datafile::DataFileReader;

pub struct Store {
    data_file_reader: Arc<dyn DataFileReader + Send + Sync>,
}

impl Store {
    pub fn new(data_file_reader: Arc<dyn DataFileReader + Send + Sync>) -> Self {
        Self { data_file_reader }
    }

    pub fn create(&self, start: DateTime<Tz>, duration: Duration, title: String) -> Id {
        let mut datafile = self.data_file_reader.read();

        let id = Id(datafile.events.keys().map(|x| x.0).min().unwrap_or(0) + 1);

        datafile
            .events
            .insert(id, Event::new(id, start, duration, title));

        self.data_file_reader.save(datafile);

        id
    }

    pub fn find_by_date(&self, day: chrono::prelude::NaiveDate) -> Vec<Event> {
        let datafile = self.data_file_reader.read();
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
