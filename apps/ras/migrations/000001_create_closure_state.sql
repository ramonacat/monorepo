CREATE TABLE closure_state (
    hostname TEXT NOT NULL PRIMARY KEY,
    current_closure TEXT,
    current_closure_updated_at TIMESTAMPTZ,
    latest_closure TEXT,
    latest_closure_updated_at TIMESTAMPTZ
)
