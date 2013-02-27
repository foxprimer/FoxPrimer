package FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign;
use Moose;
use File::Which;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankRetriever;
use FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankToFasta;
use FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Sim4Alignment;
use FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Primer3;

use namespace::autoclean;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign - Catalyst Model

=head1 DESCRIPTION

This is the sub-controller module that controls the execution of functions
to design and annotate primers for cDNA/mRNA.

=head1 AUTHOR

Jason R Dobson foxprimer@gmail.com

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 number_per_type

This Moose object is the pre-validated number of primers per type of primer
pair to make.

=cut

has number_per_type	=>	(
	is		=>	'ro',
	isa		=>	'Int',
);

=head2 product_size_string

This Moose object is the pre-validated string for the upper and lower
limits of acceptable PCR product sizes.

=cut

has product_size_string	=>	(
	is		=>	'ro',
	isa		=>	'Str',
);

=head2 intron_size

This Moose object is the pre-validated integer value for the minimum size
of an intron between two primer pairs for a pair to be considered an
"intron primer pair".

=cut

has intron_size	=>	(
	is		=>	'ro',
	isa		=>	'Int',
);

=head2 species

This Moose object contains the string of the species entered in the
dropdown box by the user on the web form.

=cut

has species	=>	(
	is		=>	'ro',
	isa		=>	'Str',
);

=head2 _mispriming_file

This Moose object is dynamically created based on which species the user
picks on the web form. This object contains the location of the appropriate
mispriming file to be used by Primer3 in scalar string format.

=cut

has _mispriming_file	=>	(
	is			=>	'ro',
	isa			=>	'Str',
	required	=>	1,
	lazy		=>	1,
	default		=>	sub {
		my $self = shift;

		if ($self->species eq 'Human') {
			return "$FindBin::Bin/../root/static/files/human_and_simple";
		} else {
			return "$FindBin::Bin/../root/static/files/rodent_and_simple";
		}
	},
	reader		=>	'mispriming_file'
);

=head2 _primer3_executable

This Moose object dynamically locates the path to the primer3 executable
'primer3_core'. If primer3_core can not be found, the program will die
horribly.

=cut

has _primer3_executable	=>	(
	is			=>	'ro',
	isa			=>	'Str',
	required	=>	1,
	lazy		=>	1,
	default		=>	sub {
		my $self = shift;
		my $primer3_executable = which('primer3_core');
		chomp($primer3_executable);
		return $primer3_executable;
	},
	reader		=>	'primer3_executable'
);

=head2 _sim4_executable

This Moose object is a dynamically created string of the path to the
executable sim4, which should be found in the user's $PATH. If it is not
found, the program will die.

=cut

has _sim4_executable	=>	(
	is			=>	'ro',
	isa			=>	'Str',
	required	=>	1,
	lazy		=>	1,
	default		=>	sub {
		my $self = shift;
		my $sim4_executable = which('sim4');
		chomp($sim4_executable);
		return $sim4_executable;
	},
	reader		=>	'sim4_executable',
);

=head2 primers_to_make

This Moose object is an Array Ref of Hash Refs containing the pertinant
information about the sequences to fectch from NCBI for the mRNA's found in
the Gene2Accession database.

Each field in the Array Ref has the following:
{
	mrna		=>	'RefSeq mRNA Accession',
	mrna_gi		=>	'NCBI GI Accession for cDNA sequence',
	dna_gi		=>	'NCBI GI Accession for genomic DNA sequence',
	dna_start	=>	'DNA position of the 5'-end of the mRNA',
	dna_stop	=>	'DNA position of the 3'-end of the mRNA',
	orientation	=>	'Which strand of DNA the mRNA is found on'
}

=cut

has primers_to_make	=>	(
	is			=>	'ro',
	isa			=>	'ArrayRef[HashRef]',
);

=head2 create_primers

This subroutine is the main subroutine for the Model. It creates the
objects of each subtype and relays the relevant information back and forth
between them. This subroutine returns the primers in an Array Ref of Hash
Refs.

=cut

sub create_primers {
	my $self = shift;

	# Run the unique_genbank subroutine to fetch the sequence objects and
	# mRNA descriptions from NCBI.
	my $sequence_objects_and_descriptions = $self->unique_genbank;

	# Pre-declare an Array Ref to hold the Hash Refs of primer information.
	my $designed_primers = [];

	# Iterate through the sequence_objects_and_descriptions, writing
	# sequence objects to file, aligning cDNA to genomic DNA, designing
	# primers, and annotating primer locations.
	foreach my $sequence_object_set (@$sequence_objects_and_descriptions) {

		# Create a
		# FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankToFasta
		# object, and run the 'write_to_fasta' subroutine to write the
		# sequence objects to file.
		my $genbank_to_fasta =
		FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankToFasta->new(
			mrna				=>	$sequence_object_set->{mrna},
			cdna_object			=>	$sequence_object_set->{mrna_object},
			genomic_dna_object	=>	$sequence_object_set->{genomic_dna_object},
		);
		my ($cdna_fh, $genomic_dna_fh) = $genbank_to_fasta->write_to_fasta;

		# Create a
		# FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Sim4Alignment
		# object and run the 'sim4_alignment' subroutine to return a Hash
		# Ref of exon coordinates and intron lengths.
		my $sim4 =
		FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Sim4Alignment->new(
			cdna_fh			=>	$cdna_fh,
			genomic_dna_fh	=>	$genomic_dna_fh
		);
		my $coordinates = $sim4->sim4_alignment;

		# Create a
		# FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Primer3 object
		# and run the 'create_primers' subroutine to return created
		# primers, any error messages, and the number of primers designed
		# by Primer3.
		my $primer3 =
		FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Primer3->new(
			product_size	=>	$self->product_size_string,
			mispriming_file	=>	$self->mispriming_file,
			primer3_path	=>	$self->primer3_executable,
			cdna_fh			=>	$cdna_fh
		);
		my ($created_primers, $primer3_errors, $number_of_primers_created)
		= $primer3->create_primers;

		# Remove the FASTA files now that the alignment has completed and
		# primers have been designed.
		unlink($cdna_fh);
		unlink($genomic_dna_fh);

		# Remove the temporary file created by Primer3
		unlink("$FindBin::Bin/../tmp/primer3/temp.out");

		# Now create an instance of
		# FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::MapPrimers to
		# run the 'map' subroutine, which will determine the top N of each
		# primer type based on the number (N) specified by the user and
		# ranked by the primer pair penalty defined by Primer3.
	}
}

=head2 unique_genbank

This subroutine is designed to ensure that only unique sequences are
fetched from NCBI. Often, there are multiple genomic DNA assemblies to
which the same cDNA sequence will be aligned. There will be a dramatic
increase in speed when the sequence objects for the cDNA are only fetched
once per RefSeq mRNA accession.

=cut

sub unique_genbank {
	my $self = shift;

	# Pre-declare an Array Ref to hold the information and sequence objects
	# for each mRNA that primers will be made for.
	my $info_and_sequence_objects = [];

	# Pre-declare a Hash Ref to hold the GI accessions for cDNA sequences
	# and their sequence objects that have already been fetched. This is
	# designed to increase speed by reducing redundant fetching of
	# sequences.
	my $cdna_sequence_objects_fetched = {};

	# Iterate through the primers_to_make Array Ref, and use
	# FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankRetriever to
	# fetch the sequence objects and mRNA descriptions for each mRNA that
	# primers will be designed for.
	foreach my $primer_to_make ( @{$self->primers_to_make} ) {

		# Create a
		# FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankRetriever
		# object.
		my $genbank =
		FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankRetriever->new(
			mrna		=>	$primer_to_make->{mrna},
			mrna_gi		=>	$primer_to_make->{mrna_gi},
			dna_gi		=>	$primer_to_make->{dna_gi},
			dna_start	=>	$primer_to_make->{dna_start},
			dna_stop	=>	$primer_to_make->{dna_stop},
			orientation	=>	$primer_to_make->{orientation},
		);

		# If the cDNA sequence has already been fetched, copy it into the
		# current Hash Ref (along with the description), then fetch the
		# genomic DNA object.
		if ( $cdna_sequence_objects_fetched->{$primer_to_make->{mrna_gi}} )
		{
			$primer_to_make->{mrna_object} =
			$cdna_sequence_objects_fetched->{$primer_to_make->{mrna_gi}}{mrna_object};
			$primer_to_make->{description} =
			$cdna_sequence_objects_fetched->{$primer_to_make->{mrna_gi}}{description};

			# Fetch the genomic DNA sequence object using the
			# get_genomic_dna_object subroutine.
			my $genomic_dna_sequence_object =
			$genbank->get_genomic_dna_object;

			# Store the genomic DNA sequence object in the Current Hash Ref
			$primer_to_make->{genomic_dna_object} =
			$genomic_dna_sequence_object;
		} else {

			# Fetch the sequence objects and descriptions by running the
			# 'get_objects' subroutine.
			my ($cdna_sequence_object, $genomic_dna_sequence_object,
				$mrna_description) = $genbank->get_objects;

			# Store the cDNA sequence object and the mRNA description in
			# the cdna_sequence_objects_fetched Hash Ref.
			$cdna_sequence_objects_fetched->{$primer_to_make->{mrna_gi}}{mrna_object}
			= $cdna_sequence_object;
			$cdna_sequence_objects_fetched->{$primer_to_make->{mrna_gi}}{description}
			= $mrna_description;

			# Store the objects and the description in the current Hash Ref
			$primer_to_make->{mrna_object} = $cdna_sequence_object;
			$primer_to_make->{genomic_dna_object} =
			$genomic_dna_sequence_object;
			$primer_to_make->{description} = $mrna_description;
		}


		# Add the Hash Ref to the info_and_sequence_objects Array Ref of
		# Hash Refs
		push(@$info_and_sequence_objects, $primer_to_make);
	}

	return $info_and_sequence_objects;
}

__PACKAGE__->meta->make_immutable;

1;
