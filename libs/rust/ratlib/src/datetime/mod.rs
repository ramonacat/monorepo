use std::fmt::Write;

use chrono::{DateTime, Datelike as _, TimeZone, Timelike as _};
use chrono_tz::Tz;
use serde::ser::SerializeTuple;
use serde::{de::Visitor, Deserializer, Serializer};

pub fn serialize_date_time_tz_option<S>(
    date_time: &Option<DateTime<Tz>>,
    se: S,
) -> Result<S::Ok, S::Error>
where
    S: Serializer,
{
    if let Some(dt) = date_time {
        return serialize_date_time_tz(dt, se);
    }

    Ok(se.serialize_none()?)
}

pub fn deserialize_date_time_tz_option<'de, D>(de: D) -> Result<Option<DateTime<Tz>>, D::Error>
where
    D: Deserializer<'de>,
{
    Ok(de.deserialize_option(OptionDateTimeTzVisitor)?)
}

struct OptionDateTimeTzVisitor;
impl<'a> Visitor<'a> for OptionDateTimeTzVisitor {
    type Value = Option<DateTime<Tz>>;

    fn expecting(&self, formatter: &mut std::fmt::Formatter) -> std::fmt::Result {
        formatter.write_str("an option value")
    }

    fn visit_some<D>(self, deserializer: D) -> Result<Self::Value, D::Error>
    where
        D: Deserializer<'a>,
    {
        Ok(Some(deserialize_date_time_tz(deserializer)?))
    }

    fn visit_none<E>(self) -> Result<Self::Value, E>
    where
        E: serde::de::Error,
    {
        Ok(None)
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

#[cfg(test)]
mod tests {
    use arbitrary::{Arbitrary, Unstructured};
    use chrono::{DateTime, NaiveDateTime, Timelike};
    use chrono_tz::Tz;
    use rand::RngCore;
    use serde::{Deserialize, Serialize};

    use super::{deserialize_date_time_tz, serialize_date_time_tz};

    #[derive(Serialize, Deserialize, Debug, PartialEq)]
    struct TestStruct {
        #[serde(
            serialize_with = "serialize_date_time_tz",
            deserialize_with = "deserialize_date_time_tz"
        )]
        pub datetime: DateTime<Tz>,
    }

    #[test]
    fn can_roundtrip_datetime() {
        for _ in 0..1000 {
            let mut random_data = [0u8; 128];
            rand::thread_rng().fill_bytes(&mut random_data);
            let mut unstructured = Unstructured::new(&random_data);
            // TODO we should consider > 1s precision!
            let datetime = NaiveDateTime::arbitrary(&mut unstructured)
                .unwrap()
                .with_nanosecond(0)
                .unwrap();
            let timezone = Tz::arbitrary(&mut unstructured).unwrap();

            let test_struct = TestStruct {
                datetime: datetime.and_local_timezone(timezone).unwrap(),
            };

            let result: TestStruct =
                serde_json::from_str(&serde_json::to_string(&test_struct).unwrap()).unwrap();

            assert_eq!(result, test_struct);
        }
    }
}
