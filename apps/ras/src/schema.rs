// @generated automatically by Diesel CLI.

diesel::table! {
    home_closure (name) {
        name -> Text,
        current_closure -> Text,
        current_closure_updated_at -> Timestamptz,
    }
}

diesel::table! {
    home_closure_state (hostname) {
        hostname -> Text,
        closure_name -> Text,
        current_closure -> Text,
        current_closure_updated_at -> Timestamptz,
    }
}

diesel::table! {
    host_closure_state (hostname) {
        hostname -> Text,
        current_closure -> Nullable<Text>,
        current_closure_updated_at -> Nullable<Timestamptz>,
        latest_closure -> Nullable<Text>,
        latest_closure_updated_at -> Nullable<Timestamptz>,
    }
}

diesel::joinable!(home_closure_state -> home_closure (closure_name));

diesel::allow_tables_to_appear_in_same_query!(home_closure, home_closure_state, host_closure_state,);
