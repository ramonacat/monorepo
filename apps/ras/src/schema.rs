// @generated automatically by Diesel CLI.

diesel::table! {
    closure_state (hostname) {
        hostname -> Text,
        current_closure -> Nullable<Text>,
        current_closure_updated_at -> Nullable<Timestamptz>,
        latest_closure -> Nullable<Text>,
        latest_closure_updated_at -> Nullable<Timestamptz>,
    }
}
