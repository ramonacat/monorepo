use chrono::{Datelike, TimeZone, Utc};
use chrono_tz::Europe::Berlin;
use colored::{Color, Colorize};
use ratlib::{calendar::event::Event, todo::Todo, PostEvent, SERVER_URL};

use crate::cli::list::render_todo;

pub(crate) fn execute(action: crate::CalendarAction) {
    let client = reqwest::blocking::Client::new();

    match action {
        crate::CalendarAction::Today => {
            let berlin_now = Berlin.from_utc_datetime(&Utc::now().naive_utc());

            let todos_becoming_valid: Vec<Todo> = client
                .get(format!(
                    "{}todos?becoming_ready_on={}",
                    SERVER_URL,
                    berlin_now.date_naive()
                ))
                .send()
                .unwrap()
                .json()
                .unwrap();

            let events_today: Vec<Event> = client
                .get(format!(
                    "{}events?date={}",
                    SERVER_URL,
                    berlin_now.date_naive()
                ))
                .send()
                .unwrap()
                .json()
                .unwrap();

            println!(
                "Today: {} {}",
                berlin_now.date_naive(),
                berlin_now.weekday()
            );

            for event in events_today {
                println!(
                    "{} ({} min) {}",
                    event.start().time().to_string().color(Color::Blue),
                    event.duration().as_secs() / 60,
                    event.title()
                );
            }

            for todo in todos_becoming_valid {
                println!("{}", render_todo(&todo));
            }
        }
        crate::CalendarAction::Add {
            when,
            duration,
            title,
        } => {
            client
                .post(format!("{}events", SERVER_URL))
                .json(&PostEvent::Add {
                    date: when,
                    duration,
                    title,
                })
                .send()
                .unwrap();
        }
    }
}
