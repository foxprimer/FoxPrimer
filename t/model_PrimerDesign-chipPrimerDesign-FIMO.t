use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";


BEGIN { use_ok 'FoxPrimer::Model::PrimerDesign::chipPrimerDesign::FIMO' }
BEGIN { use_ok
	'FoxPrimer::Model::PrimerDesign::chipPrimerDesign::twoBitToFa' }
BEGIN { use_ok
	'FoxPrimer::Model::PrimerDesign::chipPrimerDesign' }

# Create an instance of FoxPrimer::Model::PrimerDesign::chipPrimerDesign
# to get the genome ID from it.
my $chip_primer_design =
FoxPrimer::Model::PrimerDesign::chipPrimerDesign->new(
	genome	=>	'mm9',
);

# Create an instance of
# FoxPrimer::Model::PrimerDesign::chipPrimerDesign::twoBitToFa 
my $twobit_to_fa =
FoxPrimer::Model::PrimerDesign::chipPrimerDesign::twoBitToFa->new(
	genome_id		=>	$chip_primer_design->genome_id,
	chromosome		=>	'chr17',
	start			=>	'44873272',
	end				=>	'44874897',
);

# Run the 'create_temp_fasta' subroutine to return the path to the
# temporary FASTA file.
my $temp_fasta_file = $twobit_to_fa->create_temp_fasta;

# Create an instance of
# FoxPrimer::Model::PrimerDesign::chipPrimerDesign::FIMO 
my $run_fimo = FoxPrimer::Model::PrimerDesign::chipPrimerDesign::FIMO->new(
	fasta_file	=>	$temp_fasta_file,
	motif		=>	'RUNX1'
);

# Make sure the run_fimo object was created properly and that it can run
# the 'find_motifs' subroutine.
isa_ok($run_fimo,
	'FoxPrimer::Model::PrimerDesign::chipPrimerDesign::FIMO'
);
can_ok($run_fimo, 'find_motifs');

# Run the 'find_motifs' subroutine, and make sure the returned structure is
# correct.
my $motif_coordinates = $run_fimo->find_motifs;

isa_ok($motif_coordinates, 'ARRAY');
isa_ok($motif_coordinates->[0], 'HASH');
cmp_ok($motif_coordinates->[0]{end}, '==', 44874281,
	'The end coordinate was returned correctly'
);
cmp_ok($motif_coordinates->[3]{start}, '==', 44874138,
	'The start coordinate was returned correctly'
);

# Remove the temporary FASTA file.
unlink($temp_fasta_file);


done_testing();
