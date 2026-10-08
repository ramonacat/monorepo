DROP TYPE inet_endpoint;
DROP TABLE home_closure_state;
DROP TABLE home_closure;
DROP TABLE host_closure_state;

CREATE TABLE nixos_closure (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    latest_store_path TEXT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE nixos_closure_state (
    id UUID PRIMARY KEY,
    closure_id UUID NOT NULL REFERENCES nixos_closure(id),
    current_store_path TEXT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE host (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    nixos_closure_state_id UUID REFERENCES nixos_closure_state(id)
);

INSERT INTO host (id, name, nixos_closure_state_id)
    -- the closures will be filled out at runtime, once CI sends us information
    VALUES (uuidv7(), 'darkmore-control-plane-0', NULL),
        (uuidv7(), 'darkmore-control-plane-1', NULL),
        (uuidv7(), 'darkmore-control-plane-2', NULL),
        (uuidv7(), 'darkmore-worker-0', NULL),
        (uuidv7(), 'hallewell', NULL),
        (uuidv7(), 'shadowsoul', NULL),
        (uuidv7(), 'scarletwound', NULL);

CREATE TABLE home (
    id UUID PRIMARY KEY,
    hostname TEXT NOT NULL UNIQUE,
    nixos_closure_state_id UUID REFERENCES nixos_closure_state(id)
);

INSERT INTO home (id, hostname, nixos_closure_state_id)
    -- the closures will be filled out at runtime, once CI sends us information
    VALUES (uuidv7(), 'ANGELSIN', NULL),
        (uuidv7(), 'EVILLIAN', NULL),
        (uuidv7(), 'MOONFALL', NULL);

ALTER TABLE address_allocation RENAME TO ipam_address_allocation;

DROP TABLE host_ip_address;
DROP TABLE wireguard_endpoint;
DROP TABLE wireguard_tunnel_to_address_allocation;
DROP TABLE wireguard_tunnel;

CREATE TABLE ipam_live_ip (
    id UUID PRIMARY KEY,
    host_id UUID NOT NULL REFERENCES host(id),
    address INET NOT NULL,
    interface_name TEXT NOT NULL,
    allocation_id UUID REFERENCES ipam_address_allocation(id)
);

CREATE TABLE wireguard_host (
    host_id UUID PRIMARY KEY REFERENCES host(id),
    ports INT[] NOT NULL,
    addresses INET[] NOT NULL,
    public_key TEXT NOT NULL
);

CREATE TABLE wireguard_tunnel (
    id UUID PRIMARY KEY,

    initiator_id UUID NOT NULL REFERENCES host(id),
    responder_id UUID NOT NULL REFERENCES host(id),

    ipam_address_allocation_id UUID NOT NULL REFERENCES ipam_address_allocation(id),

    responder_port INTEGER NOT NULL
);
