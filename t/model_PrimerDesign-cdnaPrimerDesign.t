use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";


BEGIN { use_ok 'FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign' }

# Create a FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign object
my $cdna_primer_design =
FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign->new(
	number_per_type		=>	5,
	product_size_string	=>	'70-150',
	intron_size			=>	1000,
	species				=>	'Human',
	primers_to_make		=>	[
		{
			'dna_stop' => '227765',
			'dna_start' => '5000',
			'dna_gi' => '190341079',
			'orientation' => '+',
			'mrna_gi' => '226442782',
			'mrna' => 'NM_001024630.3'
		},
		{
			'dna_stop' => '12249159',
			'dna_start' => '12026103',
			'dna_gi' => '157812004',
			'orientation' => '-',
			'mrna_gi' => '226442782',
			'mrna' => 'NM_001024630.3'
		}
	],
);

# Make sure the object was created correctly
isa_ok($cdna_primer_design,
	'FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign'
);

# Make sure the FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign object can
# execute the 'unique_genbank' subroutine.
can_ok($cdna_primer_design, 'unique_genbank');

# Run the 'unique_genbank' subroutine, which should return an Array Ref of
# Hash Refs.
my $sequence_objects_and_descriptions =
$cdna_primer_design->unique_genbank;

# Make sure the returned data structure is an Array Ref
isa_ok($sequence_objects_and_descriptions, 'ARRAY');

# Make sure that the returned data structure contains Hash Refs
isa_ok($sequence_objects_and_descriptions->[0], 'HASH');

# Make sure the FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign object can
# execute the 'create_primers' subroutine.
can_ok($cdna_primer_design, 'create_primers');

# Run the 'create_primers' subroutine, which should return a structure of
# primer information to be entered into the FoxPrimer database and returned
# to the user.
my $designed_cdna_primers = $cdna_primer_design->create_primers;

done_testing();
