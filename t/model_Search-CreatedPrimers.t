use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";


BEGIN { use_ok 'FoxPrimer::Model::Search::CreatedPrimers' }
BEGIN { use_ok 'FoxPrimer::Model::Search::CreatedPrimers::cDNA' }
BEGIN { use_ok 'FoxPrimer::Model::Search::CreatedPrimers::ChIP' }

# Create a FoxPrimer::Model::Search::CreatedPrimers object, and then make
# sure it was created properly.
my $created_search = FoxPrimer::Model::Search::CreatedPrimers->new(
	search_string			=>	'Runx Pan pan',
	accessions_to_search	=>	['NM_001111021.1'],
);

isa_ok($created_search, 'FoxPrimer::Model::Search::CreatedPrimers');

# Make sure the created_search object can execute the
# 'search_created_cdna_primers' subroutine and that the primers returned
# are unique.
can_ok($created_search, 'search_created_cdna_primers');
my $unique_primers = $created_search->search_created_cdna_primers;
isa_ok($unique_primers, 'ARRAY');

# Test to make sure the returned primers are unique.
my $seen_primers = {};
foreach my $unique_primer (@$unique_primers) {

	my $primer_string = join(".", $unique_primer->left_primer_sequence,
		$unique_primer->right_primer_sequence, $unique_primer->accession
	);

	# Make sure this primer has not been seen before
	ok( ! $seen_primers->{$primer_string}, 'The primer is unique');

	# Define the primer in the seen_primers Hash Ref
	$seen_primers->{$primer_string} = 1;
}

done_testing();
