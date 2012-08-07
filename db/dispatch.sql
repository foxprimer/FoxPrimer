--
-- Create a database for the storage and retrial of mRNA accession information
--

CREATE TABLE genes2accession ( rna_accession  TEXT, rna_gi NUMERIC, genomic_gi NUMERIC, genomic_start NUMERIC, genomic_stop NUMERIC, orientation TEXT, PRIMARY KEY ( rna_gi, genomic_gi ));
