CREATE TABLE host_group (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL
);

INSERT INTO host_group (id, name) VALUES(uuidv7(), 'kubernetes/darkmore');

ALTER TABLE host ADD COLUMN host_group_id UUID REFERENCES host_group(id);
