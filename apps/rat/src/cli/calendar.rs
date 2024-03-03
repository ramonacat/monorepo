use chrono::{Datelike, TimeZone, Utc};
use chrono_tz::Europe::Berlin;
use colored::{Color, Colorize};

use crate::{calendar::store::Store, cli::list::render_todo};

pub(crate) fn execute(
    event_store: &Store,
    todo_store: &crate::todo::store::Store,
    action: crate::CalendarAction,
) {
    match action {
        crate::CalendarAction::Today => {
            let berlin_now = Berlin.from_utc_datetime(&Utc::now().naive_utc());
            let events_today = event_store.find_by_date(berlin_now.date_naive());
            let todos_becoming_valid = todo_store.find_becoming_valid_on(berlin_now.date_naive());

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
            event_store.create(when, duration, title);
        }
    }
}
