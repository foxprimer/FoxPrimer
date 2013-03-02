DROP TABLE IF EXISTS genomes;

CREATE TABLE genomes (
	id INTEGER PRIMARY KEY,
	genome TEXT UNIQUE
);

DROP TABLE IF EXISTS twobit;

CREATE TABLE twobit (
	id INTEGER PRIMARY KEY,
	genome INTEGER REFERENCES genomes(id),
	path TEXT
);

DROP TABLE IF EXISTS chromosomesizes;

CREATE TABLE chromosomesizes (
	id INTEGER PRIMARY KEY,
	genome INTEGER REFERENCES genomes(id),
	path TEXT
);

DROP TABLE IF EXISTS genebodies;

CREATE TABLE genebodies (
	id INTEGER PRIMARY KEY,
	genome INTEGER REFERENCES genomes(id),
	accession TEXT,
	chromosome TEXT,
	txstart INTEGER,
	txend INTEGER,
	strand TEXT
);
