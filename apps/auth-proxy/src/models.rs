use chrono::{DateTime, Utc};
use diesel::{Selectable, deserialize::Queryable};
use uuid::Uuid;

#[derive(Debug, Queryable, Selectable)]
#[diesel(table_name = crate::schema::tokens, check_for_backend(diesel::pg::Pg), primary_key(id))]
pub struct Token {
    pub id: Uuid,
    pub name: String,
    pub value: String,
    pub expiration: DateTime<Utc>,
}

#[derive(Debug, Queryable, Selectable)]
#[diesel(table_name = crate::schema::sessions, check_for_backend(diesel::pg::Pg), primary_key(id))]
#[allow(unused)]
pub struct Session {
    pub id: String,
    pub expiration: Option<DateTime<Utc>>,
    pub contents: String,
}
