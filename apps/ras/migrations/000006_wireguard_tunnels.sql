CREATE TABLE address_allocation (
    id UUID NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    parent_id UUID REFERENCES address_allocation(id),
    cidr CIDR NOT NULL
);

INSERT INTO address_allocation (id, name, parent_id, cidr) 
VALUES
    (uuidv7(), 'private 10.0.0.0/8', NULL, '10.0.0.0/8'),
    (uuidv7(), 'private 172.16.0.0/12', NULL, '172.16.0.0/12'),
    (uuidv7(), 'private 192.168.0.0/16', NULL, '192.168.0.0/16');

INSERT INTO address_allocation (id, name, parent_id, cidr)
VALUES
    (
        uuidv7(), 
        'kubernetes/darkmore', 
        (SELECT id FROM address_allocation WHERE cidr='10.0.0.0/8'),
        '10.0.0.0/11'
    ),
    (
        uuidv7(), 
        'home', 
        (SELECT id FROM address_allocation WHERE cidr='10.0.0.0/8'),
        '10.32.0.0/14'
    ),
    (
        uuidv7(), 
        'global routers', 
        (SELECT id FROM address_allocation WHERE cidr='10.0.0.0/8'),
        '10.255.0.0/16'
    );

INSERT INTO address_allocation (id, name, parent_id, cidr) 
VALUES
    (
        uuidv7(), 
        'tunnels', 
        (SELECT id FROM address_allocation WHERE cidr='10.0.0.0/11'),
        '10.255.240.0/20'
    );

CREATE TABLE wireguard_tunnel (
    id UUID NOT NULL PRIMARY KEY,
    initiator_hostname TEXT NOT NULL,
    listener_hostname TEXT NOT NULL,
    UNIQUE (initiator_hostname, listener_hostname)
);

CREATE TABLE wireguard_tunnel_to_address_allocation (
    wireguard_tunnel_id UUID NOT NULL REFERENCES wireguard_tunnel(id),
    address_allocation_id UUID NOT NULL REFERENCES address_allocation(id),
    PRIMARY KEY(wireguard_tunnel_id, address_allocation_id)
);
