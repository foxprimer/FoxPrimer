package FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::MapPrimers;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::MapPrimers - Catalyst Model

=head1 DESCRIPTION

This module is designed to determine where the primers designed by Primer3
are located with respect to the intron-exon junctions defined by Sim4.
Then, the type of primer is defined based on these positional coordinates
and the information for the primers are returned to the user.

=head1 AUTHOR

Jason R Dobson foxprimer@gmail.com

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 number_per_type

This Moose object contains the pre-validated scalar integer for the number
of primers per type of primer the user would like to have returned.

=cut

has number_per_type	=>	(
	is			=>	'ro',
	isa			=>	'Int',
);

=head2 number_of_alignments

This Moose object contains the scalar integer value for the number of
alignments found by Sim4

=cut

has number_of_alignments	=>	(
	is			=>	'ro',
	isa			=>	'Int',
);

=head2 designed_primers

This Moose object contains the data structure of primers designed by
Primer3 in the form of a Hash Ref

=cut

has	designed_primers	=>	(
	is			=>	'ro',
	isa			=>	'HashRef',
);

=head2 number_of_primers

This Moose object contains the integer value for the number of primers
designed by Primer3 for the user-defined cDNA.

=cut

has	number_of_primers	=>	(
	is			=>	'ro',
	isa			=>	'Int',
);

=head2 coordinates

This Moose object contains the exon coordinates and intron lengths parse
from Sim4 results in Hash Ref format.

=cut

has	coordinates	=>	(
	is			=>	'ro',
	isa			=>	'HashRef',
);

=head2 map

This subroutine iterates through the primers designed by Primer3 and
determines the type of primer based on coordinates returned by Sim4. Based
on the max number of primers per type the user has defined, this subroutine
will iterate through the created primers by increasing primer penalty score
(defined by Primer3) and attempt to reach the max allowable per type until
all primers are exhausted (whichever comes first). An Array Ref of primers
to be inserted into the FoxPrimer database and returned to the user is
returned by this subroutine.

=cut

sub map {
	my $self = shift;

	# Iterate through each alignment defined by Sim4 to determine the
	# relative primer positions based on intron/exon junctions.
	for ( my $alignment = 1; $alignment <= $self->number_of_alignments;
		$alignment++ ) {

		# Define an integer value for the four times of primers that will
		# be defined.
		my $junction_primer_number = 0;
		my $exon_primer_number = 0;
		my $smaller_exon_primer_number = 0;
		my $intra_exon_primer_number = 0;

		# Iterate through all of the primers that have been created by
		# Primer3 for the given cDNA sequence.
		for ( my $primer_pair = 0; $primer_pair < $self->number_of_primers;
			$primer_pair++ ) {

		}
	}
}

__PACKAGE__->meta->make_immutable;

1;
