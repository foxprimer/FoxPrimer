package FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::MapPrimers;
use Moose;
use namespace::autoclean;
use Carp;

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

=head2 intron_size

This Moose object contains the pre-validated scalar integer for the minimum
intron size for the primers to flank.

=cut

has intron_size	=>	(
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

=head2 mrna

This Moose object contains the pre-validated RefSeq mRNA accession string.

=cut

has	mrna	=>	(
	is			=>	'ro',
	isa			=>	'Str',
);

=head2 description

This Moose object contains the mRNA description returned from NCBI.

=cut

has description	=>	(
	is			=>	'ro',
	isa			=>	'Str'
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

	# Pre-declare an Array Ref to hold the insert statement that will be
	# used to insert the primers in the FoxPrimer created primers database
	# and passed to the cDNA primer design template toolkit page to be
	# parsed and returned to the user.
	my $mapped_primers = [];

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

			# If any of the primer types has not met the user-defined
			# maximum number per type to design, determine the type of
			# primer pair
			if ( $junction_primer_number < $self->number_per_type ||
				$exon_primer_number < $self->number_per_type ||
				$smaller_exon_primer_number < $self->number_per_type ||
				$intra_exon_primer_number < $self->number_per_type ) {

				my $primer_type = $self->determine_primer_type(
					$alignment,
					$primer_pair
				);

				# If the primer pair type is defined and the
				# number_per_type threshold has not been reached for the
				# type of primer defined for the current primer pair, run
				# the 'create_insert_statement' subroutine to add the
				# insert statement to the mapped_primers Array Ref.
				unless ( ! $primer_type || 
					$primer_type eq 'Undefined' ) {

					if ( $primer_type eq 'Intra-Exon Primer' &&
						$intra_exon_primer_number < $self->number_per_type)
					{
						push(@$mapped_primers,
							$self->create_insert_statement($primer_pair)
						);

						# Increase the count for this type of primer
						$intra_exon_primer_number++;
					} elsif ( $primer_type eq 'Junction Spanning Primers'
						&&
						$junction_primer_number < $self->number_per_type) {
						push(@$mapped_primers,
							$self->create_insert_statement($primer_pair)
						);

						# Increase the count for this type of primer
						$junction_primer_number++;
					} elsif ( $primer_type =~ /^Exon Primer Pair/ 
						&&
						$exon_primer_number < $self->number_per_type) {
						push(@$mapped_primers,
							$self->create_insert_statement($primer_pair)
						);

						# Increase the count for this type of primer
						$exon_primer_number++;
					} elsif ( $primer_type =~ /^Smaller Exon Primer Pair/
						&&
						$smaller_exon_primer_number <
						$self->number_per_type) {
						push(@$mapped_primers,
							$self->create_insert_statement($primer_pair)
						);

						# Increase the count for this type of primer
						$smaller_exon_primer_number++;
					}
				}
			}
		}
	}

	return $mapped_primers;
}

=head2 determine_primer_type

This subroutine is given the alignment number and primer pair number to
determine what type of primer is it based on the coordinates and primer
positions.

=cut

sub determine_primer_type {
	my ($self, $alignment_number, $primer_pair_number) = @_;

	# Extract the left primer coordinates by running the
	# 'extract_primer_coordinates' subroutine.
	my ($left_primer_five_prime, $left_primer_three_prime,
		$left_primer_length) = $self->extract_primer_coordinates(
		$primer_pair_number,
		'Left'
	);
	
	# Extract the right primer coordinates by running the
	# 'extract_primer_coordinates' subroutine.
	my ($right_primer_five_prime, $right_primer_three_prime,
		$right_primer_length) = $self->extract_primer_coordinates(
		$primer_pair_number,
		'Right'
	);
	
	# Define the left primer position by running the
	# 'determine_primer_position' subroutine.
	my $left_primer_position = $self->determine_primer_position(
		$alignment_number,
		$primer_pair_number,
		'left'
	);
	$self->designed_primers->{'Primer Pair ' . $primer_pair_number}{
	'Left Primer Position'} = $left_primer_position;

	# Define the right primer position by running the
	# 'determine_primer_position' subroutine.
	my $right_primer_position = $self->determine_primer_position(
		$alignment_number,
		$primer_pair_number,
		'right'
	);
	$self->designed_primers->{'Primer Pair ' . $primer_pair_number}{
	'Right Primer Position'} = $right_primer_position;

	# Ensure that the location of both primers has been defined
	if ( $left_primer_position ne 'Undefined' &&
		$right_primer_position ne 'Undefined' ) {

		# If the primers fall in the same exon, they are Intra-Exon Primers
		if ( $left_primer_position eq $right_primer_position ) {

			# Return a string indicating that the primer pair is defined as
			# intra-exon primers
			$self->designed_primers->{'Primer Pair ' .
			$primer_pair_number}{'Primer Pair Type'} = 
			'Intra-Exon Primers';
			return 'Intra-Exon Primers';

			# If either of the primers is a junction spanning primer, then
			# the pair is deemed to be Junction Spanning Primers.
		} elsif (
			$left_primer_position =~ /^Junction/ ||
			$right_primer_position =~ /^Junction/ ) {

			# Return a string indicating that the primer pair is defined as
			# Junction Spanning Primers
			$self->designed_primers->{'Primer Pair ' .
			$primer_pair_number}{'Primer Pair Type'} =
			'Junction Spanning Primers';
			return 'Junction Spanning Primers';

			# If the primers are in different exons, determine the size and
			# sum of the Introns between the exons to which the primers are
			# within.
		} else {

			# Pre-define integer values for the integer number of the exon
			# to which each primer is within.
			my $left_primer_exon = 0;
			my $right_primer_exon = 0;

			# Use regular expressions to extract the exon number from the
			# primer position strings.
			if ($left_primer_position =~ /^Inside of Exon (\d+)$/) {
				$left_primer_exon = $1;
			}
			if ($right_primer_position =~ /^Inside of Exon (\d+)$/) {
				$right_primer_exon = $1;
			}

			# Ensure that the exon numbers have been defined for each
			# primer before calculating the sum of the intron lengths
			# between the exons on which the primers are located.
			if ( $left_primer_exon > 0 &&
				$right_primer_exon > 0 ) {

				# Pre-define an integer to hold the value for the sum of
				# all introns between the primers.
				my $intron_sum = 0;

				# Iterate from the left primer exon number to the right
				# primer exon number, adding the size of each intron
				# between the two exons to the intron sum.
				for( my $intron_number = $left_primer_exon;
					$intron_number < $right_primer_exon;
					$intron_number++ ) {
					$intron_sum += $self->coordinates->{'Alignment ' .
					$alignment_number}{'Intron ' . $intron_number}{'Size'}
					if $self->coordinates->{'Alignment ' .
					$alignment_number}{'Intron ' . $intron_number}{'Size'};
				}

				# Determine whether the sum of the introns between the
				# primers meets the minimum threshold set by the user.
				if ($intron_sum >= $self->intron_size) {
					$self->designed_primers->{'Primer Pair ' .
					$primer_pair_number}{'Primer Pair Type'} = 
					'Exon Primer Pair: ' . $intron_sum . 'bp';
					return 'Exon Primer Pair: ' . $intron_sum . 'bp';
				} else {
					$self->designed_primers->{'Primer Pair ' .
					$primer_pair_number}{'Primer Pair Type'} = 
					'Smaller Exon Primer Pair: ' . $intron_sum . 'bp';
					return 'Smaller Exon Primer Pair: ' . $intron_sum .
					'bp';
				}
			}
		}
	} else {

		# Return a string indicating that the primer pair was unable to be
		# mapped.
		return 'Undefined';
	}
}

=head2 extract_primer_coordinates

This subroutine is passed the primer coordinates string, and a scalar
string indicating whether this primer is the 'left' or 'right' primer. This
subroutine parses the information and returns three items: the five prime
position of the primer, the three prime position of the primer and the
length of the primer. Each variable returned should be a scalar integer.

=cut

sub extract_primer_coordinates {
	my ($self, $primer_pair_number, $left_or_right) = @_;

	# Pre-declare scalar integers for the five prime position, three prime
	# position, and primer length.
	my $five_prime_position = 0;
	my $three_prime_position = 0;
	my $length = 0;
	
	# Pre-declare a scalar string to hold the primer coordinates.
	my $primer_coordinates = '';

	# Based on whether this primer is the left primer or the right primer,
	# store the primer coordinates string in the primer_coordinates
	# variable
	if ( $left_or_right eq 'Left' || $left_or_right eq 'left' ) {
		$primer_coordinates = $self->designed_primers->{
		'Primer Pair ' . $primer_pair_number}{'Left Primer Coordinates'};
	} elsif ( $left_or_right eq 'Right' || $left_or_right eq 'right' ) {
		$primer_coordinates = $self->designed_primers->{
		'Primer Pair ' . $primer_pair_number}{'Right Primer Coordinates'};
	} else {
		croak "\n\nYou must define whether this primer is the left " . 
		"or right primer.\n\n";
	}

	# Extract the five prime coordinate and the primer length from the
	# primer_coordinates string.
	($five_prime_position, $length) = split(/,/, $primer_coordinates);

	# If the primer was not extracted, end execution.
	unless( $five_prime_position && $length ) {
		croak "\n\nThe primer coordinates string was not properly " .
		"formatted.\n\n Primer coordinates: $primer_coordinates\n\n";
	}

	# Based on whether this primer is the left primer or the right primer,
	# determine the three prime coordinate of the primer.
	if ( $left_or_right eq 'Left' || $left_or_right eq 'left' ) {
		$three_prime_position = $five_prime_position + $length;
	} elsif ( $left_or_right eq 'Right' || $left_or_right eq 'right' ) {
		$three_prime_position = $five_prime_position - $length;
	} else {
		croak "\n\nYou must define whether this primer is the left " . 
		"or right primer.\n\n";
	}

	# Store the coordinates.
	$self->designed_primers->{'Primer Pair ' . $primer_pair_number}{
	lc($left_or_right) . '_primer_five_prime'} = $five_prime_position;
	$self->designed_primers->{'Primer Pair ' . $primer_pair_number}{
	lc($left_or_right) . '_primer_three_prime'} = $three_prime_position;
	$self->designed_primers->{'Primer Pair ' . $primer_pair_number}{
	lc($left_or_right) . '_primer_length'} = $length;

	return ($five_prime_position, $three_prime_position, $length);
}

=head2 determine_primer_position

This subroutine is passed three arguments: the current alignment being
used, the primer pair number to annotate, and whether this primer is the
left or right primer.

=cut

sub determine_primer_position {
	my ($self, $alignment_number, $primer_pair_number, $left_or_right) =
	@_;

	# Copy the 5' and 3' coordinates of the current primer into scalar
	# variables.
	my $primer_five_prime = $self->designed_primers->{'Primer Pair ' .
	$primer_pair_number}{lc($left_or_right) . '_primer_five_prime'};
	my $primer_three_prime = $self->designed_primers->{'Primer Pair ' .
	$primer_pair_number}{lc($left_or_right) . '_primer_three_prime'};

	# Iterate through the exons in the current alignment determining which
	# exon(s) the primer is located on and what type of relationship the
	# primer has to the exon coordinates.
	for (my $exon = 1; $exon <= $self->coordinates->{'Alignment ' .
		$alignment_number}{'Number of Exons'}; $exon++) {

		# Copy the 5' and 3' coordinates of the current exon into scalar
		# variables
		my $exon_five_prime = $self->coordinates->{'Alignment ' .
		$alignment_number}{'Exon ' . $exon}{mRNA}{Start};
		my $exon_three_prime = $self->coordinates->{'Alignment ' .
		$alignment_number}{'Exon ' . $exon}{mRNA}{Stop};

		# Depending on whether this is the right or left primer, determine
		# whether the primer is found within the current exon.
		if ( $left_or_right eq 'left' ) {

			# If both the 5'-end of the primer is greater than the 5'-end
			# of the exon and the 3'-end of the primer is less than the
			# 3'-end of the exon, then the primer is within the exon.
			if ( 
				$exon_five_prime <= $primer_five_prime
				&&
				$exon_three_prime >= $primer_three_prime ) {

				# Return a string indicating that the current primer falls
				# within the current exon.
				return 'Inside of Exon ' . $exon;

				# If both ends of the primer are not located within the
				# exon, test to see if the primer spans the junction with
				# the next exon.	
			} elsif ( 
				$exon_three_prime >= $primer_five_prime
				&&
				$exon_three_prime <= $primer_three_prime ) {
				
				# If the primer overlaps the current exon by at least 7bp
				# and the next exon by at least 4bp, then the primer is an
				# exon junction primer.
				if (
					(
						( $exon_three_prime - $primer_five_prime ) 
						>= 7 
					)

					&&

					(
						( $primer_three_prime - $exon_three_prime )
						>= 4
					) ) {

					# Return a string indicating that the current primer
					# is spanning the junction between the current exon and
					# the next exon.
					return 'Junction of Exons ' . $exon . ' and ' .
					($exon+1);
				}
			}
		} elsif ( $left_or_right eq 'right' ) {

			# If the 3'-end of the primer is greater than the 5'-end of the
			# exon and the 5'-end of the primer is less than the 3'-end of
			# the exon, then the primer is within the current exon.
			if ( 
				$exon_five_prime <= $primer_three_prime

				&&

				$exon_three_prime >= $primer_five_prime ) {

				# Return a string indicating that the current primer falls
				# within the current exon.
				return 'Inside of Exon ' . $exon;

				# If both ends of the primer are not located within the
				# exon, test to see if the primer spans the junction with
				# the next exon.	
			} elsif (
				$exon_three_prime >= $primer_three_prime
				&&
				$exon_three_prime <= $primer_five_prime ) {

				# If the primer overlaps the next exon by at least 7bp and
				# the current exon by at least 4bp, then the primer is an
				# exon junction primer.
				if ( 
					(
						( $exon_three_prime - $primer_three_prime )
						>= 4
					)

					&&

					(
						( $primer_five_prime - $exon_three_prime )
						>= 7
					) ) {

					# Return a string indicating that the current primer
					# is spanning the junction between the current exon and
					# the next exon.
					return 'Junction of Exons ' . $exon . ' and ' .
					($exon+1);
				}
			}
		} else {
			croak "\n\nTo run the 'determine_primer_position' subroutine "
			. "you must define whether the current primer is the 'left' " .
			"or 'right' primer.\n\n";
		}
	}

	# If this subroutine was unable to define a type of primer return
	# 'Undefined'. This likely means the primer spans a junction, but does
	# not have enough overlap on either side to be defined as an
	# junction-spanning primer.
	return 'Undefined';
}

=head2 create_insert_statement

This subroutine is passed the primer pair number of primer pair in the
designed_primers Moose object, and creates a Hash Ref insert statement to
be used to insert the primer pair information into the FoxPrimer database.

=cut

sub create_insert_statement {
	my ($self, $primer_pair_number) = @_;

	# Create a Hash Ref to hold the primer pair information
	my $insert_statement = {
		accession					=>	$self->{mrna},
		description					=>	$self->{description},
		primer_pair_type			=>	
			$self->designed_primers->{'Primer Pair ' .
			$primer_pair_number}{'Primer Pair Type'},

		primer_pair_penalty			=>	
			$self->designed_primers->{'Primer Pair ' .
			$primer_pair_number}{'Product Penalty'},

		left_primer_position		=>	
			$self->designed_primers->{'Primer Pair ' .
			$primer_pair_number}{'Left Primer Position'},

		right_primer_position		=>	
			$self->designed_primers->{'Primer Pair ' .
			$primer_pair_number}{'Right Primer Position'},

		product_size				=>	
			$self->designed_primers->{'Primer Pair ' .
			$primer_pair_number}{'Product Size'},

		left_primer_sequence		=>	
			$self->designed_primers->{'Primer Pair ' .
			$primer_pair_number}{'Left Primer Sequence'},

		right_primer_sequence		=>	
			$self->designed_primers->{'Primer Pair ' .
			$primer_pair_number}{'Right Primer Sequence'},

		left_primer_length			=>	
			$self->designed_primers->{'Primer Pair ' .
			$primer_pair_number}{'left_primer_length'},

		right_primer_length			=>	
			$self->designed_primers->{'Primer Pair ' .
			$primer_pair_number}{'right_primer_length'},

		left_primer_tm				=>	
			$self->designed_primers->{'Primer Pair ' .
			$primer_pair_number}{'Left Primer Tm'},

		right_primer_tm				=>	
			$self->designed_primers->{'Primer Pair ' .
			$primer_pair_number}{'Right Primer Tm'},

		left_primer_five_prime		=>	
			$self->designed_primers->{'Primer Pair ' .
			$primer_pair_number}{'left_primer_five_prime'},

		left_primer_three_prime		=>	
			$self->designed_primers->{'Primer Pair ' .
			$primer_pair_number}{'left_primer_three_prime'},

		right_primer_five_prime		=>	
			$self->designed_primers->{'Primer Pair ' .
			$primer_pair_number}{'right_primer_five_prime'},

		right_primer_three_prime	=>	
			$self->designed_primers->{'Primer Pair ' .
			$primer_pair_number}{'right_primer_three_prime'},
	};

	return $insert_statement;
}

__PACKAGE__->meta->make_immutable;

1;
