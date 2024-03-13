use std::time::Duration;

use chrono::{DateTime, Datelike, TimeZone, Timelike};
use chrono_tz::Tz;
use serde::{de::Visitor, ser::SerializeTuple, Deserialize, Deserializer, Serialize, Serializer};

#[derive(Serialize, Deserialize, Debug, Hash, Eq, PartialEq, Copy, Clone)]
pub struct Id(pub u32);

#[derive(Serialize, Deserialize, Debug)]
pub struct Event {
    id: Id,
    #[serde(
        serialize_with = "serialize_date_time_tz",
        deserialize_with = "deserialize_date_time_tz"
    )]
    start: DateTime<Tz>,
    duration: Duration,

    title: String,
}

impl Event {
    pub fn new(id: Id, start: DateTime<Tz>, duration: Duration, title: String) -> Self {
        Self {
            id,
            start,
            duration,
            title,
        }
    }

    pub fn start(&self) -> DateTime<Tz> {
        self.start
    }

    pub fn duration(&self) -> Duration {
        self.duration
    }

    pub fn title(&self) -> &str {
        &self.title
    }
}

pub fn serialize_date_time_tz<S>(date_time: &DateTime<Tz>, se: S) -> Result<S::Ok, S::Error>
where
    S: Serializer,
{
    let mut tuple = se.serialize_tuple(7)?;

    tuple.serialize_element::<i32>(&date_time.year())?;
    tuple.serialize_element::<u32>(&date_time.month())?;
    tuple.serialize_element::<u32>(&date_time.day())?;
    tuple.serialize_element::<u32>(&date_time.hour())?;
    tuple.serialize_element::<u32>(&date_time.minute())?;
    tuple.serialize_element::<u32>(&date_time.second())?;

    tuple.serialize_element(date_time.timezone().name())?;

    tuple.end()
}

pub fn deserialize_date_time_tz<'de, D>(de: D) -> Result<DateTime<Tz>, D::Error>
where
    D: Deserializer<'de>,
{
    de.deserialize_tuple(7, DateTimeTzVisitor)
}

struct DateTimeTzVisitor;

impl<'a> Visitor<'a> for DateTimeTzVisitor {
    type Value = DateTime<Tz>;

    fn expecting(&self, formatter: &mut std::fmt::Formatter) -> std::fmt::Result {
        formatter.write_str("a 7-element tuple")
    }

    fn visit_seq<A>(self, mut seq: A) -> Result<Self::Value, A::Error>
    where
        A: serde::de::SeqAccess<'a>,
    {
        let year: i32 = seq.next_element()?.unwrap();
        let month: u32 = seq.next_element()?.unwrap();
        let day: u32 = seq.next_element()?.unwrap();
        let hour: u32 = seq.next_element()?.unwrap();
        let minute: u32 = seq.next_element()?.unwrap();
        let second: u32 = seq.next_element()?.unwrap();

        let timezone: &str = seq.next_element()?.unwrap();

        let tz: Tz = timezone.parse().unwrap();

        Ok(tz
            .with_ymd_and_hms(year, month, day, hour, minute, second)
            .unwrap())
    }
}
