use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";


BEGIN { use_ok
	'FoxPrimer::Model::PrimerDesign::chipPrimerDesign::twoBitToFa' }
BEGIN { use_ok
	'FoxPrimer::Model::PrimerDesign::chipPrimerDesign' }

# Create an instance of FoxPrimer::Model::PrimerDesign::chipPrimerDesign
# to get the genome ID from it.
my $chip_primer_design =
FoxPrimer::Model::PrimerDesign::chipPrimerDesign->new(
	genome	=>	'dm3',
);

# Create an instance of
# FoxPrimer::Model::PrimerDesign::chipPrimerDesign::twoBitToFa 
my $twobit_to_fa =
FoxPrimer::Model::PrimerDesign::chipPrimerDesign::twoBitToFa->new(
	genome_id		=>	$chip_primer_design->genome_id,
	chromosome		=>	'chrX',
	start			=>	'86043',
	end				=>	'87242',
);

# Make sure that the twobit_to_fa object was created correctly.
isa_ok($twobit_to_fa,
	'FoxPrimer::Model::PrimerDesign::chipPrimerDesign::twoBitToFa'
);

# Make sure that the twobit_to_fa object can execute the
# 'create_temp_fasta' subroutine.
can_ok($twobit_to_fa, 'create_temp_fasta');

# Run the 'create_temp_fasta' subroutine to return the path to the
# temporary FASTA file.
my $temp_fasta_file = $twobit_to_fa->create_temp_fasta;

# Remove the temporary FASTA file.
unlink($temp_fasta_file);

done_testing();
