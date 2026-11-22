CREATE TABLE host_to_host_group (
    host_id UUID NOT NULL,
    host_group_id UUID NOT NULL,

    PRIMARY KEY (host_id, host_group_id)
);

INSERT INTO host_to_host_group (host_id, host_group_id)
    SELECT id, host_group_id FROM host WHERE host_group_id IS NOT NULL;

ALTER TABLE host DROP COLUMN host_group_id;
