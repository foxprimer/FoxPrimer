DROP TABLE IF EXISTS cdna_primers;
--
-- Create a database for the storage and display of qPCR primers
--

CREATE TABLE cdna_primers (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	accession TEXT,
	description TEXT,
	primer_pair_type TEXT,
	primer_pair_penalty NUMERIC,
	left_primer_position TEXT,
	right_primer_position TEXT,
	product_size INTEGER,
	left_primer_sequence TEXT,
	right_primer_sequence TEXT,
	left_primer_length INTEGER,
	right_primer_length INTEGER,
	left_primer_tm NUMERIC,
	right_primer_tm NUMERIC,
	left_primer_five_prime INTEGER,
	left_primer_three_prime INTEGER,
	right_primer_five_prime INTEGER,
	right_primer_three_prime INTEGER,
	unique( Left_Primer_Sequence, Right_Primer_Sequence, accession) ON CONFLICT REPLACE);

CREATE TABLE chip_primers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
	left_primer_sequence TEXT,
	right_primer_sequence TEXT,
	left_primer_tm NUMBER,
	right_primer_tm NUMBER,
	genome TEXT,
	chromosome TEXT,
	left_primer_five_prime INTEGER,
	left_primer_three_prime INTEGER,
	right_primer_five_prime INTEGER,
	right_primer_three_prime INTEGER,
	product_size INTEGER,
	primer_pair_penalty NUMBER,
    relative_locations TEXT,
	UNIQUE(left_primer_sequence, right_primer_sequence, genome) ON CONFLICT REPLACE
);
