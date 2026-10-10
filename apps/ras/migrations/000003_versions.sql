CREATE TABLE versions (
    versioned_item TEXT,
    store_path TEXT,
    version BIGINT NOT NULL,

    PRIMARY KEY(versioned_item, store_path)
);
