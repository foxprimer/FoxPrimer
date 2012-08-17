CREATE TABLE chip_primer_pairs_general (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	left_primer_sequence TEXT,
	right_primer_sequence TEXT,
	left_primer_tm NUMBER,
	right_primer_tm NUMBER,
	chromosome TEXT,
	left_primer_five_prime INTEGER,
	left_primer_three_prime INTEGER,
	right_primer_five_prime INTEGER,
	right_primer_three_prime INTEGER,
	product_size INTEGER,
	primer_pair_penalty NUMBER
);
CREATE TABLE relative_locations (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	location TEXT UNIQUE
);
CREATE TABLE chip_primer_pairs_relative_locations (
	pair_id INTEGER REFERENCES chip_primer_pairs_general(id),
	location_id INTEGER REFERENCES relative_locations(id)
);
