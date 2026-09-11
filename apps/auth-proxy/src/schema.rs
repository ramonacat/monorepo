// @generated automatically by Diesel CLI.

diesel::table! {
    sessions (id) {
        id -> Text,
        expiration -> Nullable<Timestamptz>,
        contents -> Text,
    }
}

diesel::table! {
    tokens (id) {
        id -> Uuid,
        name -> Text,
        value -> Text,
        expiration -> Timestamptz,
    }
}

diesel::allow_tables_to_appear_in_same_query!(sessions, tokens,);
