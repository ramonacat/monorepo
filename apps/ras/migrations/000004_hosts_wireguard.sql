CREATE TYPE inet_endpoint AS (
    address INET,
    port INT2
);

CREATE TABLE wireguard_endpoint (
    hostname TEXT NOT NULL PRIMARY KEY,
    public_key TEXT NOT NULL,

    -- endpoint can be null in case the machine is behind a NAT and can only be the initiator
    endpoint inet,
    port int check (port > 0 AND port <= 65535 AND (port IS NOT NULL OR endpoint IS NULL))
);

CREATE TABLE host_ip_address (
    hostname TEXT NOT NULL PRIMARY KEY,
    address INET NOT NULL UNIQUE
);
