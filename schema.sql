CREATE TABLE gates (
    uuid       TEXT NOT NULL PRIMARY KEY,
    gate_url   TEXT NOT NULL,
    owner_name TEXT NOT NULL,
    owner_uuid TEXT NOT NULL,
    region     TEXT NOT NULL,
    last_seen  TIMESTAMP NOT NULL DEFAULT NOW(),
    active     BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE connections (
    origin_uuid      TEXT NOT NULL REFERENCES gates(uuid),
    destination_uuid TEXT NOT NULL REFERENCES gates(uuid),
    connection_ts    TIMESTAMP NOT NULL DEFAULT NOW()
);