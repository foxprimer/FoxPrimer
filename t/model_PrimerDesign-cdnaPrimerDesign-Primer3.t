use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use File::Which;

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

# Make sure the object was created properly.
isa_ok($primer3,
	'FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Primer3'
);

# Make sure the primer3 object can execute the 'cdna_sequence' subroutine.
can_ok($primer3, 'cdna_sequence');

# Extract the cDNA sequence and make sure the returned variable is a
# Bio::SeqIO object.
my $cdna_seq = $primer3->cdna_sequence;
isa_ok($cdna_seq, 'Bio::Seq');

# Make sure the primer3 object can execute the 'create_primers' subroutine.
can_ok($primer3, 'create_primers');

# Run the create_primers subroutine to return a Hash Ref of primers, a
# string that can contain an error message and a scalar integer for the
# number of primers designed.
my ($primers_designed, $error_messages, $number_of_primers_designed) =
$primer3->create_primers;

# Make sure the returned objects are correct.
isa_ok($primers_designed, 'HASH');
cmp_ok($number_of_primers_designed, '==', 500, 
	'The correct number of primers was designed'
);

# Remove the FASTA files
unlink($cdna_fh);
unlink($genomic_fh);

done_testing();
