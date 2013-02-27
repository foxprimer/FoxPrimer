use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";


BEGIN { use_ok 'FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankRetriever' }

# Pre-define an Array Ref of Hash Refs holding the information for GenBank
# sequence objects to retrieve.

my $accessions_to_fetch = [
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
];

# Iterate through the Array Ref of Hash Refs of sequence information
foreach my $accession_to_fetch (@$accessions_to_fetch) {
	# Create a
	# FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankRetriever
	# object
	my $genbank =
	FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankRetriever->new(
		mrna		=>	$accession_to_fetch->{mrna},
		mrna_gi		=>	$accession_to_fetch->{mrna_gi},
		dna_gi		=>	$accession_to_fetch->{dna_gi},
		dna_start	=>	$accession_to_fetch->{dna_start},
		dna_stop	=>	$accession_to_fetch->{dna_stop},
		orientation	=>	$accession_to_fetch->{orientation},
	);

	# Make sure the object was properly created.
	isa_ok($genbank,
		'FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankRetriever'
	);

	# Make sure the object can run the 'get_objects' subroutine.
	can_ok($genbank, 'get_objects');

	# Fetch the sequence objects and mRNA description
	my ($cdna_seq_obj, $gen_dna_seq_obj, $mrna_desc)  =
	$genbank->get_objects;

	# Make sure that the objects fetched are GenBank sequence objects
	isa_ok($cdna_seq_obj, 'Bio::Seq::RichSeq');
	isa_ok($gen_dna_seq_obj, 'Bio::Seq');
}



done_testing();
