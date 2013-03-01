package FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankRetriever;
use Moose;
use Bio::DB::GenBank;
use namespace::autoclean;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankRetriever - Catalyst Model

=head1 DESCRIPTION

This module uses the BioPerl module Bio::DB::GenBank to interact with NCBI
to fetch sequence objects for the cDNA and corresponding genomic DNA
sequences.

=head1 AUTHOR

Jason R Dobson foxprimer@gmail.com

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 mrna

This Moose object holds a string for the RefSeq mRNA accession.

=cut

has mrna	=>	(
	is			=>	'ro',
	isa			=>	'Str',
);

=head2 mrna_gi

This Moose object holds the integer value for the NCBI cDNA GI sequence
accession.

=cut

has mrna_gi	=>	(
	is			=>	'ro',
	isa			=>	'Int',
);

=head2 dna_gi

This Moose object holds the integer value for the NCBI genomic sequence GI
accession.

=cut

has dna_gi	=>	(
	is			=>	'ro',
	isa			=>	'Int',
);

=head2 dna_start

This Moose object holds the integer value for the 5'-position of the mRNA
on the genomic DNA.

=cut

has dna_start	=>	(
	is			=>	'ro',
	isa			=>	'Int',
);

=head2 dna_stop

This Moose object holds the integer value for the 3'-position of the mRNA
on the genomic DNA.

=cut

has dna_stop	=>	(
	is			=>	'ro',
	isa			=>	'Int',
);

=head2 orientation

This Moose object holds the character symbol (either '-' or '+') defining
which strand of genomic DNA the mRNA is found on.

=cut

has orientation	=>	(
	is			=>	'ro',
	isa			=>	'Str',
);

=head2 get_objects

This subroutine creates an instance of Bio::DB::GenBank and interacts with
NCBI to fetch the sequence objects for both the cDNA and genomic DNA. Both
objects are returned by the
FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankRetriever::get_objects
subroutine. Also, this subroutine also returns the description of the mRNA
in scalar string format.

=cut

sub get_objects {
	my $self = shift;

	# Get the cDNA sequence object
	my $cdna_sequence_object = $self->get_cdna_object;

	# Store the mRNA description in a string
	my $mrna_description = $cdna_sequence_object->desc();

	# Get the genomic DNA sequence object
	my $genomic_dna_sequence_object = $self->get_genomic_dna_object;

	# Return the sequence objects and the mRNA description.
	return ($cdna_sequence_object, $genomic_dna_sequence_object,
		$mrna_description
	);
}

=head2 get_cdna_object

This subroutine is used for the retrieval of the cDNA sequence object from
NCBI.

=cut

sub get_cdna_object {
	my $self = shift;

	# Create a new GenBank instance.
	my $bank = Bio::DB::GenBank->new();

	# Fetch the cDNA sequence and return the GenBank sequence object.
	return $bank->get_Seq_by_gi($self->mrna_gi);
}

=head2 get_genomic_dna_object

This subroutine is used for the retrieval of the genomic DNA object from
NCBI.

=cut

sub get_genomic_dna_object {
	my $self = shift;

	# Based on which strand of the genomic DNA the mRNA is found, determine
	# which number will be used for Bio::DB::GenBank (1 for positive strand
	# and 2 for negative strand).
	my $strand = '';
	if ( $self->orientation eq '+') {
		$strand = 1;
	} elsif ( $self->orientation eq '-' ) {
		$strand = 2;
	} else {
		die "The orientation of the mRNA was not properly designated as"
		. " either '+' or '-'\n\n";
	}

	# Create a new GenBank instance.
	my $bank = Bio::DB::GenBank->new(
		-format		=>	'Fasta',
		-seq_start	=>	$self->dna_start,
		-seq_stop	=>	$self->dna_stop,
		-strand		=>	$strand,
	);

	# Fetch the genomic DNA object, and return the sequence object.
	return $bank->get_Seq_by_acc($self->dna_gi);
}

__PACKAGE__->meta->make_immutable;

1;
