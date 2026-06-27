use chrono::{DateTime, Utc};
use diesel::{
    Selectable,
    associations::{Associations, Identifiable},
    deserialize::Queryable,
};

#[derive(Queryable, Selectable)]
#[diesel(
    table_name = crate::schema::host_closure_state,
    check_for_backend(diesel::pg::Pg),
    primary_key(hostname)
)]
pub struct HostClosureState {
    pub hostname: String,
    pub current_closure: Option<String>,
    pub current_closure_updated_at: Option<DateTime<Utc>>,
    pub latest_closure: Option<String>,
    pub latest_closure_updated_at: Option<DateTime<Utc>>,
}

#[derive(Queryable, Selectable, Identifiable)]
#[diesel(
    table_name = crate::schema::home_closure,
    check_for_backend(diesel::pg::Pg),
    primary_key(name)
)]
pub struct HomeClosure {
    pub name: String,
    pub current_closure: String,
    pub current_closure_updated_at: DateTime<Utc>,
}

#[derive(Queryable, Selectable, Associations, Identifiable)]
#[diesel(
    table_name = crate::schema::home_closure_state,
    check_for_backend(diesel::pg::Pg),
    belongs_to(HomeClosure, foreign_key=closure_name),
    primary_key(hostname)
)]
pub struct HomeClosureState {
    pub hostname: String,
    pub closure_name: String,
    pub current_closure: String,
    pub current_closure_updated_at: DateTime<Utc>,
}
