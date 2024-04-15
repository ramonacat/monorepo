CREATE TABLE hosts (
    hostname TEXT NOT NULL PRIMARY KEY,
    last_seen TIMESTAMPTZ NOT NULL,
    running_closure_path TEXT NOT NULL,
    last_running_closure_change TIMESTAMPTZ NULL
);
