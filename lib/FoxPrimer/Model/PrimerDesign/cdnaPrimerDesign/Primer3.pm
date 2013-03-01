package FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Primer3;
use Moose;
use namespace::autoclean;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Bio::SeqIO;
use FoxPrimer::Model::Updated_Primer3_Run;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Primer3 - Catalyst Model

=head1 DESCRIPTION

This module creates primers for cDNA sequences and returns a Hash Ref of
the information about each primer pair made for the given cDNA sequence.

=head1 AUTHOR

Jason R Dobson foxprimer@gmail.com

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 product_size

This Moose object is the pre-validated product size string used by Primer3
as constraints for primer products.

=cut

has product_size	=>	(
	is			=>	'ro',
	isa			=>	'Str'
);

=head2 mispriming_file

This Moose object holds the string (defined by the species chosen by the
user) of the file location that will be used by Primer3 as the mispriming
library of sequences.

=cut

has mispriming_file	=>	(
	is			=>	'ro',
	isa			=>	'Str',
);

=head2 primer3_path

This Moose object holds the pre-validated path (in string format) to the
'primer3_core' executable.

=cut

has primer3_path	=>	(
	is			=>	'ro',
	isa			=>	'Str'
);

=head2 cdna_fh

This Moose object holds the string-format path to the FASTA format cDNA
sequence file for which primers will be designed.

=cut

has cdna_fh	=>	(
	is			=>	'ro',
	isa			=>	'Str'
);

=head2 create_primers

This subroutine creates a FoxPrimer::Model::Updated_Primer3_Run object and
runs primer3 for the cDNA sequence in the file provided by the user.
Primers and their cognate information is returned in a Hash Ref. If no
primers are designed, an error message is returned along with an empty Hash
Ref. The final variable returned in the number of primers designed by
Primer3.

=cut

sub create_primers {
	my $self = shift;

	# Pre-declare a Hash Ref to hold the primers created.
	my $created_primers = {};

	# Pre-declare a String to hold any error messages
	my $error_messages = '';

	# Extract the cDNA sequence by running the 'cdna_sequence' subroutine
	my $cdna_seq = $self->cdna_sequence;

	# Create a FoxPrimer::Model::Updated_Primer3_Run object
	my $primer3 = FoxPrimer::Model::Updated_Primer3_Run->new(
		-seq		=>	$cdna_seq,
		-outfile	=>	"$FindBin::Bin/../tmp/primer3/temp.out",
		-path		=>	$self->primer3_path
	);

	# Add the mispriming library, number to make, and a product size range
	# to the FoxPrimer::Model::Updated_Primer3_Run object.
	$primer3->add_targets(
		'PRIMER_MISPRIMING_LIBRARY'		=>	$self->mispriming_file,
		'PRIMER_NUM_RETURN'				=>	500,
		'PRIMER_PRODUCT_SIZE_RANGE'		=>	$self->product_size,
	);

	# Run primer3 and return the results as a Hash Ref
	my $results = $primer3->run;

	# Make sure that primer3 was able to create primers under the
	# conditions specified by the user. If not return an error message.
	if ( $results->number_of_results > 0 ) {

		# Iterate through the primers have have been designed and extract
		# their coordinates.
		for (my $i = 0; $i < $results->number_of_results; $i++) {

			# Store the primer results in a local Hash Ref
			my $primer_result = $results->primer_results($i);

			# Store the primer information in the created_primers Hash Ref
			$created_primers->{'Primer Pair ' . $i}{
			'Left Primer Coordinates'} = $primer_result->{PRIMER_LEFT};

			$created_primers->{'Primer Pair ' . $i}{
			'Right Primer Coordinates'} = $primer_result->{PRIMER_RIGHT};

			$created_primers->{'Primer Pair ' . $i}{
			'Left Primer Sequence'} = $primer_result->{PRIMER_LEFT_SEQUENCE};

			$created_primers->{'Primer Pair ' . $i}{
			'Right Primer Sequence'} =
			$primer_result->{PRIMER_RIGHT_SEQUENCE};

			$created_primers->{'Primer Pair ' . $i}{
			'Left Primer Tm'} = $primer_result->{PRIMER_LEFT_TM};

			$created_primers->{'Primer Pair ' . $i}{
			'Right Primer Tm'} = $primer_result->{PRIMER_RIGHT_TM};

			$created_primers->{'Primer Pair ' . $i}{
			'Product Size'} = $primer_result->{PRIMER_PAIR_PRODUCT_SIZE};

			$created_primers->{'Primer Pair ' . $i}{
			'Product Penalty'} = $primer_result->{PRIMER_PAIR_PENALTY};
		}

		return ($created_primers, $error_messages,
			$results->number_of_results);
	} else {

		$error_messages = "Primer3 was unable to design primers for " . 
		"the cDNA sequence under the conditions you have specified.";

		return ($created_primers, $error_messages, 0);
	}
}

=head2 cdna_sequence

This subroutine takes the user-defined path to the cDNA sequence in FASTA
format and extracts the sequence using Bio::SeqIO.

=cut

sub cdna_sequence {
	my $self = shift;

	# Create a Bio::SeqIO object for the cDNA file provided by the user.
	my $seqio = Bio::SeqIO->new(
		-file	=>	$self->cdna_fh,
		-format	=>	'FASTA'
	);

	# Extract the sequence from the file and return it
	return $seqio->next_seq;
}

__PACKAGE__->meta->make_immutable;

1;
