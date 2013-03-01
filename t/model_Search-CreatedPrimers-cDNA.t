use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";


BEGIN { use_ok 'FoxPrimer::Model::Search::CreatedPrimers::cDNA' }

# Create a FoxPrimer::Model::Search::CreatedPrimers::cDNA object, and then
# make sure it was created properly.
my $cdna_search = FoxPrimer::Model::Search::CreatedPrimers::cDNA->new(
	search_string			=>	'Runx Pan pan',
	accessions_to_search	=>	['NM_001111021.1'],
);

isa_ok($cdna_search, 'FoxPrimer::Model::Search::CreatedPrimers::cDNA');

# Make sure the cdna_search object can execute the 'search_mrna_accessions'
# subroutine.
can_ok($cdna_search, 'search_mrna_accessions');

# Execute the search_mrna_accessions and make sure the Array Ref of primers
# returned is correct.
my $accession_matches = $cdna_search->search_mrna_accessions;

isa_ok($accession_matches, 'ARRAY');

cmp_ok($accession_matches->[0]->accession, 'eq', 'NM_001111021.1',
	'The accession search returned properly'
);

# Make sure the cdna_search object can execute the 'search_descriptions'
# subroutine.
can_ok($cdna_search, 'search_descriptions');

# Execute the 'search_descriptions' subroutine, which returns an Array Ref
# of primer information, then make sure the object was correctly returned.
my $description_matches = $cdna_search->search_descriptions;

isa_ok($description_matches, 'ARRAY');

cmp_ok($description_matches->[0]->accession, 'eq', 'NM_001111021.1',
	'The corrent primer pair was found'
);

cmp_ok($description_matches->[-1]->accession, 'eq', 'NM_001014685.3',
	'The corrent primer pair was found'
);

# Make sure the cdna_search can run the 'return_unique' subroutine.
can_ok($cdna_search, 'return_unique');

# Add the description search results to the accession search results
push(@$accession_matches, @$description_matches);

# Run the 'return_unique' subroutine and test to make sure that the
# function has executed correctly and removed duplicate primers.
my $unique_primers = $cdna_search->return_unique($accession_matches);

isa_ok($unique_primers, 'ARRAY');
cmp_ok(@$unique_primers, '<', @$accession_matches, 
	'Less primers returned by the \'return_unique\' subroutine.'
);

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

# Test to make sure the cdna_search can execute the search_cdna_database
# and that the execution of this subroutine returns an Array Ref of unique
# cDNA primers.
can_ok($cdna_search, 'search_cdna_database');

my $full_unique_primers = $cdna_search->search_cdna_database;

isa_ok($full_unique_primers, 'ARRAY');

# Test to make sure all primer pairs returned are unique.
my $full_seen = {};

foreach my $full_unique_primer (@$full_unique_primers) {

	my $primer_string = join('.',
		$full_unique_primer->left_primer_sequence,
		$full_unique_primer->right_primer_sequence,
		$full_unique_primer->accession
	);

	# Make sure the primer pair is unique.
	ok( ! $full_seen->{$primer_string}, 'The primer is unique');

	# Define the primer pair as seen.
	$full_seen->{$primer_string} = 1;
}

# Make sure the same number of primers is returned by both methods
cmp_ok(@$full_unique_primers, '==', @$unique_primers,
	'The same number of primers is returned by both methods'
);

done_testing();
