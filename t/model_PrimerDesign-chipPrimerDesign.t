use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";


BEGIN { use_ok 'FoxPrimer::Model::PrimerDesign::chipPrimerDesign' }

# Create an instance of FoxPrimer::Model::PrimerDesign::chipPrimerDesign
# for the purpose of testing the 'chromosome_sizes' subroutine.
my $get_chromosome_sizes =
FoxPrimer::Model::PrimerDesign::chipPrimerDesign->new(
	genome	=>	'mm9'
);

# Make sure the object is created properly.
isa_ok($get_chromosome_sizes,
	'FoxPrimer::Model::PrimerDesign::chipPrimerDesign'
);

# Make sure the object can execute the 'chromosome_sizes' subroutine.
can_ok($get_chromosome_sizes, 'chromosome_sizes');

# Run the 'chromosome_sizes' subroutine to return a Hash Ref of chromosome
# sizes and chromosome length. Then make sure the object was returned
# correctly.
my $chrom_sizes = $get_chromosome_sizes->chromosome_sizes;

isa_ok($chrom_sizes, 'HASH');

# Create a new instance of FoxPrimer::Model::PrimerDesign::chipPrimerDesign
# to test the 'extend_coordinates' subroutine.
my $test_extend = FoxPrimer::Model::PrimerDesign::chipPrimerDesign->new(
	genome			=>	'mm9',
	product_size	=>	'70-150',
);

# Make sure the test_extend object was created properly.
isa_ok($test_extend, 'FoxPrimer::Model::PrimerDesign::chipPrimerDesign');

# Make sure the get_chromosome_sizes object can run the
# 'extend_coordinates' subroutine.
can_ok($test_extend, 'extend_coordinates');

# Run the extend_coordinates subroutine several times to ensure that the
# Hash Ref returned each time is correctly formatted.
my $extended_coordinates_1 = $test_extend->extend_coordinates(
	{
		chromosome	=>	'chr14',
		start		=>	200,
		end			=>	500
	}
);
cmp_ok($extended_coordinates_1->{start}, '==', 200,
	'The start coordinate returned correctly'
);
my $extended_coordinates_2 = $test_extend->extend_coordinates(
	{
		chromosome	=>	'chr14',
		start		=>	50,
		end			=>	100
	}
);
cmp_ok($extended_coordinates_2->{start}, '==', 1,
	'The start coordinate returned correctly'
);
cmp_ok($extended_coordinates_2->{end}, '==', 225,
	'The end coordinate returned correctly'
);
my $extended_coordinates_3 = $test_extend->extend_coordinates(
	{
		chromosome	=>	'chr14',
		start		=>	125194764,
		end			=>	125194799
	}
);
cmp_ok($extended_coordinates_3->{end}, '==', 125194864,
	'The end coordinate returned correctly'
);
my $extended_coordinates_4 = $test_extend->extend_coordinates(
	{
		chromosome	=>	'chr14',
		start		=>	200,
		end			=>	220
	}
);
cmp_ok($extended_coordinates_4->{target}, 'eq', '140,20',
	'The target sequence returned correctly'
);

done_testing();
