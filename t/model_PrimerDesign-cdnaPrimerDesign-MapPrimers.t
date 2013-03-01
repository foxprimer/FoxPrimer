use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use File::Which;

BEGIN { use_ok
	'FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::MapPrimers' }
BEGIN { use_ok
	'FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Sim4Alignment' }
BEGIN { use_ok 'FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Primer3'
	}
BEGIN { use_ok
	'FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankToFasta' }
BEGIN { use_ok
	'FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankRetriever' }

# Create a
# FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankRetriever
# object.
my $genbank =
FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankRetriever->new(
	mrna		=>	'NM_001024630.3',
	mrna_gi		=>	226442782,
	dna_gi		=>	157812004,
	dna_start	=>	12026103,
	dna_stop	=>	12249159,
	orientation	=>	'-',
);

# Fetch the cDNA and genomic DNA sequence objects
my ($cdna_seq_obj, $gen_dna_seq_obj, $mrna_desc) = $genbank->get_objects;

# Create a FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankToFasta
# object.
my $genbank_to_fa =
FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankToFasta->new(
	cdna_object			=>	$cdna_seq_obj,
	genomic_dna_object	=>	$gen_dna_seq_obj,
	mrna				=>	'NM_001024630.3',
);

# Execute the 'write_to_fasta' subroutine, returning scalar strings
# corresponding to the location of the FASTA files.
my ($cdna_fh, $genomic_fh) = $genbank_to_fa->write_to_fasta;

# Create a FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Sim4Alignment
# object.
my $sim4 =
FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Sim4Alignment->new(
	cdna_fh			=>	$cdna_fh,
	genomic_dna_fh	=>	$genomic_fh
);

# Execute the 'sim4_alignment' and return a Hash Ref of exon coordinates
# and intron lengths.
my $coordinates = $sim4->sim4_alignment;

# Store the path to the mispriming file in a scalar
my $mispriming_fh = "$FindBin::Bin/../root/static/files/human_and_simple";

# Create a FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Primer3
# object.
my $primer3 =
FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Primer3->new(
	product_size		=>	'70-150',
	mispriming_file		=>	$mispriming_fh,
	primer3_path		=>	which('primer3_core'),
	cdna_fh				=>	$cdna_fh,
);

# Run the create_primers subroutine to return a Hash Ref of primers, a
# string that can contain an error message and a scalar integer for the
# number of primers designed.
my ($primers_designed, $error_messages, $number_of_primers_designed) =
$primer3->create_primers;

# Create a FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::MapPrimers
# object, and make sure that it was created properly.
my $map_primers =
FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::MapPrimers->new(
	number_per_type			=>	5,
	intron_size				=>	1000,
	number_of_alignments	=>	$coordinates->{'Number of Alignments'},
	designed_primers		=>	$primers_designed,
	number_of_primers		=>	$number_of_primers_designed,
	coordinates				=>	$coordinates,
	mrna					=>	'NM_001024630.3',
	description				=>	$mrna_desc,
);
isa_ok($map_primers,
	'FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::MapPrimers'
);

# Make sure the map_primers object can execute the
# 'extract_primer_coordinates' subroutine and correctly return three
# integers.
can_ok($map_primers, 'extract_primer_coordinates');

my ($primer_five_prime, $primer_three_prime, $primer_length) =
$map_primers->extract_primer_coordinates(
	5,
	'Right'
);

cmp_ok($primer_five_prime, '==', 3802,
	'The five prime coordinate of the primer was properly extracted'
);
cmp_ok($primer_three_prime, '==', 3782,
	'The three prime coordinate of the primer was properly extracted'
);
cmp_ok($primer_length, '==', 20,
	'The primer length was properly extracted'
);

# Run the same subroutine again for the left primer so the coordinates will
# be stored
$map_primers->extract_primer_coordinates(
	5,
	'Left'
);

# Make sure the map_primers object can execute the
# 'determine_primer_position' subroutine.
can_ok($map_primers, 'determine_primer_position');

# Run the 'determine_primer_position' subroutine for both the left and
# right primers making sure that the correct definitions have been
# returned.
my $left_primer_location = $map_primers->determine_primer_position(
	1,
	5,
	'left'
);
my $right_primer_location = $map_primers->determine_primer_position(
	1,
	5,
	'right'
);

# Make sure that the correct string has been returned for the given
# primers.
cmp_ok($right_primer_location, 'eq', 'Inside of Exon 9', 
	'The right primer was properly defined inside of Exon 9'
);
cmp_ok($left_primer_location, 'eq', 'Inside of Exon 9', 
	'The left primer was properly defined inside of Exon 9'
);

# Make sure the 'determine_primer_type' subroutine can be executed by the
# map_primers object.
can_ok($map_primers, 'determine_primer_type');

# Run the 'determine_primer_type' subroutine to return the primer pair type
# in scalar string.
my $intra_exon_primer_type = $map_primers->determine_primer_type(
	1,
	5
);
my $junction_primer_type = $map_primers->determine_primer_type(
	1,
	4
);
my $exon_primer_type = $map_primers->determine_primer_type(
	1,
	3
);
my $smaller_exon_primer_type = $map_primers->determine_primer_type(
	1,
	12
);

# Make sure the correct primer type was returned.
cmp_ok($intra_exon_primer_type, 'eq', 'Intra-Exon Primers',
	'The correct primer type was returned for ' .
	'Intra-Exon Primers'
);
cmp_ok($junction_primer_type, 'eq', 'Junction Spanning Primers',
	'The correct primer type was returned for ' .
	'Junction Spanning Primers'
);
like($exon_primer_type, qr/^Exon Primer Pair/,
	'The correct primer type was returned for ' .
	'Exon Primers'
);
like($smaller_exon_primer_type, qr/^Smaller Exon Primer Pair/,
	'The correct primer type was returned for ' .
	'Smaller Exon Primers'
);

# Make sure the map_primers object can run the 'create_insert_statement'
# subroutine.
can_ok($map_primers, 'create_insert_statement');

# Run the 'create_insert_statement' subroutine, and make sure that it
# returns a Hash Ref of primer information to be inserted into the
# FoxPrimer database.
my $single_insert = $map_primers->create_insert_statement(
	5
);

isa_ok($single_insert, 'HASH');
cmp_ok($single_insert->{primer_pair_type}, 'eq', 'Intra-Exon Primers',
	'The primer insert statement is correctly formatted'
);

# Make sure the map_primers object can run the 'map' subroutine
can_ok($map_primers, 'map');

# Run the 'map' subroutine to return an Array Ref of insert statements in
# the form of Hash Refs.
my $insert_statement = $map_primers->map;

# Make sure the object returned by the 'map' subroutine is properly
# formatted.
isa_ok($insert_statement, 'ARRAY');
isa_ok($insert_statement->[0], 'HASH');
cmp_ok(@{$insert_statement}, '<=', 20,
	'The correct number of primers have been made for each primer type'
);

# Remove the FASTA files
unlink($cdna_fh);
unlink($genomic_fh);

done_testing();
