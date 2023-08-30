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
    origin_uuid      TEXT REFERENCES gates(uuid) ON DELETE SET NULL,
    destination_uuid TEXT REFERENCES gates(uuid) ON DELETE SET NULL,
    connection_ts    TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE gate_coordinates(
    gate_uuid TEXT NOT NULL PRIMARY KEY REFERENCES gates(uuid) ON DELETE CASCADE,
    one       INT NOT NULL,
    two       INT NOT NULL,
    three     INT NOT NULL,
    four      INT NOT NULL,
    five      INT NOT NULL,
    six       INT NOT NULL,
    seven     INT NOT NULL,
    UNIQUE(one, two, three, four, five, six, seven)
);