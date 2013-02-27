use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Data::Dumper;


BEGIN { use_ok
	'FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Sim4Alignment' }
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

# Make sure the object was created properly
isa_ok($sim4,
	'FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Sim4Alignment'
);

# Make sure the object can execute the 'sim4_alignment' subroutine.
can_ok($sim4, 'sim4_alignment');

# Execute the 'sim4_alignment' and return a Hash Ref of exon coordinates
# and intron lengths.
my $coordinates = $sim4->sim4_alignment;

# Make sure the coordinates variable is a Hash Ref.
isa_ok($coordinates, 'HASH');

# Remove the FASTA files
unlink($cdna_fh);
unlink($genomic_fh);

done_testing();
