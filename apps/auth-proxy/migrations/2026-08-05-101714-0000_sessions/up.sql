CREATE TABLE sessions (
    id TEXT PRIMARY KEY,
    expiration TIMESTAMP WITH TIME ZONE,
    contents TEXT NOT NULL
)
