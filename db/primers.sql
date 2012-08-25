--
-- Create a database for the storage and display of qPCR primers
--

CREATE TABLE primers (
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
