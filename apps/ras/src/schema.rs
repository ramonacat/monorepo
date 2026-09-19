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

diesel::table! {
    host_ip_address (hostname) {
        hostname -> Text,
        address -> Inet,
    }
}

diesel::table! {
    versions (versioned_item, store_path) {
        versioned_item -> Text,
        store_path -> Text,
        version -> Int8,
    }
}

diesel::table! {
    wireguard_endpoint (hostname) {
        hostname -> Text,
        public_key -> Text,
        endpoint -> Nullable<Inet>,
        port -> Nullable<Int4>,
    }
}

diesel::joinable!(home_closure_state -> home_closure (closure_name));

diesel::allow_tables_to_appear_in_same_query!(
    home_closure,
    home_closure_state,
    host_closure_state,
    host_ip_address,
    versions,
    wireguard_endpoint,
);
