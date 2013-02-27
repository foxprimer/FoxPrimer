use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN { use_ok 'FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankToFasta' }
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

# Make sure the
# FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankToFasta object
# was created properly.
isa_ok($genbank_to_fa,
	'FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankToFasta'
);

# Make sure the genbank_to_fa object can execute the 'write_to_fasta'
# subroutine.
can_ok($genbank_to_fa, 'write_to_fasta');

# Execute the 'write_to_fasta' subroutine, returning scalar strings
# corresponding to the location of the FASTA files.
my ($cdna_fh, $genomic_fh) = $genbank_to_fa->write_to_fasta;

# Make sure that the files exist and are readable
ok(-r $cdna_fh, 'The cDNA FASTA file exists and is readable');
ok(-r $genomic_fh, 'The genomic DNA FASTA file exists and is readable');

# Remove the FASTA files
unlink($cdna_fh);
unlink($genomic_fh);

done_testing();
