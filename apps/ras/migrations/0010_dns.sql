CREATE TABLE dns_zone (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL,
    serial INT8 NOT NULL,
    refresh int NOT NULL,
    retry int NOT NULL,
    expire int NOT NULL,
    negative_response_ttl int NOT NULL,
    default_ttl int NOT NULL
);

CREATE TABLE dns_record (
    id UUID PRIMARY KEY,
    zone_id UUID NOT NULL REFERENCES dns_zone (id),
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    rrdatas TEXT[] NOT NULL,
    ttl int,
    UNIQUE (zone_id, name)
);

INSERT INTO
    dns_zone (id, name, serial, refresh, retry, expire, negative_response_ttl, default_ttl)
VALUES
    (
        UUIDV7(),
        'i.ramona.fun',
        1,
        3600,
        1800,
        3600*6,
        600,
        60 
    );
