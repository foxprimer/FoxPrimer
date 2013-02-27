use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

# Make sure that we can use the FoxPrimer::Model::PrimerDesign module.
BEGIN { use_ok 'FoxPrimer::Model::PrimerDesign' }

# Create a FoxPrimer::Model::PrimerDesign object
my $primer_design_object = FoxPrimer::Model::PrimerDesign->new(
	accessions_string	=>	'NM_001015051.3,NM_001024630,NM_99119',
);

# Make sure that the primer_design_object has been created correctly.
isa_ok($primer_design_object, 'FoxPrimer::Model::PrimerDesign');

# Make sure that the gene2accession_schema is a FoxPrimer::Schema object.
can_ok($primer_design_object, 'gene2accession_schema');
my $gene2accession_schema = $primer_design_object->gene2accession_schema;
isa_ok($gene2accession_schema, 'FoxPrimer::Schema');

# Make sure that the primer design object can execute the
# valid_refseq_accessions subroutine
can_ok($primer_design_object, 'valid_refseq_accessions');

# Run the valid_refseq_accessions subroutine with two correct RefSseq mRNA
# accession string (one with the version modifier, and one without), and
# one invalid RefSeq mRNA accession.
my ($error_messages, $accessions_to_design) =
$primer_design_object->valid_refseq_accessions;

# Make sure that the valid_refseq_accessions subroutine returns two Array
# Refs
isa_ok($error_messages, 'ARRAY');
isa_ok($accessions_to_design, 'ARRAY');

# Make sure that one and only one error message is returned.
cmp_ok(@$error_messages, '==', 1, 
	'There was one error message correctly returned'
);
cmp_ok(@$error_messages, '!=', 2, 
	'There was one error message correctly returned'
);

# Make sure that each item in the accessions_to_design Array Ref is a Hash
# Ref
foreach my $accession_to_design (@$accessions_to_design) {
	isa_ok($accession_to_design, 'HASH');
}

done_testing();
