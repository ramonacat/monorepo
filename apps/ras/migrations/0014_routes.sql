CREATE TABLE routing_route (
    id UUID PRIMARY KEY,
    target_host_id UUID NOT NULL REFERENCES host(id),
    target_ips INET[] NOT NULL,
    target_cidr CIDR NOT NULL,
    blackhole BOOL NOT NULL
);
