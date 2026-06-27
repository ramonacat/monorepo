use chrono::{DateTime, Utc};
use diesel::{Selectable, deserialize::Queryable};

#[derive(Queryable, Selectable)]
#[diesel(table_name = crate::schema::host_closure_state, check_for_backend(diesel::pg::Pg))]
pub struct ClosureState {
    pub hostname: String,
    pub current_closure: Option<String>,
    pub current_closure_updated_at: Option<DateTime<Utc>>,
    pub latest_closure: Option<String>,
    pub latest_closure_updated_at: Option<DateTime<Utc>>,
}
