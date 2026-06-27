ALTER TABLE closure_state RENAME TO host_closure_state;

CREATE TABLE home_closure (
    name TEXT NOT NULL PRIMARY KEY,
    current_closure TEXT NOT NULL,
    current_closure_updated_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE home_closure_state (
    hostname TEXT NOT NULL PRIMARY KEY,
    closure_name TEXT NOT NULL REFERENCES home_closure(name),
    current_closure TEXT NOT NULL,
    current_closure_updated_at TIMESTAMPTZ NOT NULL
);
