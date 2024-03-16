use crate::app::AppState;
use axum::{
    extract::{Query, State},
    Json,
};
use chrono::NaiveDate;
use ratlib::{calendar::event::Event, PostEvent};
use serde::Deserialize;
use std::borrow::BorrowMut;

#[derive(Deserialize)]
pub struct EventQuery {
    date: NaiveDate,
}

pub async fn get(
    State(state): State<AppState>,
    Query(query): Query<EventQuery>,
) -> Json<Vec<Event>> {
    let mut event_store_guard = state.event_store.lock().await;
    let event_store = event_store_guard.borrow_mut();

    Json((event_store).find_by_date(query.date))
}

pub async fn post(State(state): State<AppState>, Json(request): Json<PostEvent>) -> Json<String> {
    let mut event_store_guard = state.event_store.lock().await;
    let event_store = event_store_guard.borrow_mut();

    match request {
        PostEvent::Add {
            date,
            duration,
            title,
        } => {
            event_store.create(date, duration, title);
        }
    }

    Json("ok".to_string())
}
