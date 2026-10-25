CREATE TABLE load_balancer (
    id UUID PRIMARY KEY,
    host_group_id UUID NOT NULL REFERENCES host_group(id),
    ports JSONB NOT NULL,
    address_allocation_id UUID NOT NULL REFERENCES ipam_address_allocation(id)
);

INSERT INTO ipam_address_allocation(id, name, parent_id, cidr) VALUES(uuidv7(), 'load balancers', (SELECT id FROM ipam_address_allocation WHERE name = ''), '10.254.0.0/16');
