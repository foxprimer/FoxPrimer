package FoxPrimer::Model::mRNA_Primer_Design::Map_Primers;
use Moose;
use namespace::autoclean;
use Data::Dumper;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::mRNA_Primer_Design::Map_Primers - Catalyst Model

=head1 DESCRIPTION

This module provides the map subroutine which based on the number of
primers to design per type.

=head1 AUTHOR

Jason R Dobson,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 Moose declarations

This section is for Moose declarations of things that should be created upon object
creation

=cut

has number_per_type	=>	(
	is		=>	'rw',
	isa		=>	'Int',
);

has intron_size		=>	(
	is		=>	'rw',
	isa		=>	'Int',
);

=head2 map

This subroutine provides the main business logic for the mRNA_Primer_Design
function by determining the positions of each primer relative to intron
exon junctions as well as intron sizes between primer pairs.

=cut

sub map {
	my ($self, $structure) = @_;
	# Pre-declare an Array Ref of Hash Refs to hold the mapped primers to be inserted
	# into the database and returned to the user
	my $mapped_primers = [];
	# Iterate through each mRNA for which primers have been designed
	foreach my $mrna (@$structure) {
		# Iterate through each alignment defined by Sim4 and determine the relative primer
		# positions based on the intron/exon junctions
		for ( my $alignment = 1; $alignment <= $mrna->{coordinates}{'Number of Alignments'}; $alignment++ ) {
			# Define an integer value of zero for four type of primes that can be mapped
			my $junction_primer_number = 0;
			my $exon_primer_number = 0;
			my $smaller_exon_primer_number = 0;
			my $intra_exon_primer_number = 0;
			# Iterate through all of the primers that have been created by Primer3 for this cDNA sequence
			for ( my $primer_pair = 0; $primer_pair < $mrna->{'Number of Primers'}; $primer_pair++ ) {
				# If any of the primer types has not met the user-defined maximum number per type to design
				# determine the type of primer pair
				if ($junction_primer_number < $self->number_per_type ||
					$exon_primer_number < $self->number_per_type ||
					$smaller_exon_primer_number < $self->number_per_type ||
					$intra_exon_primer_number < $self->number_per_type ) {
					# Send the alignment coordinates, the primer_pair information, and the desired minimum
					# intron size to the private subroutine _determine_primer_type, which will return the
					# type of primer the primer pair is and return the coordinates of the primer pair relative
					# to intron exon junctions
					my ($primer_type, $mapped_primer) = $self->_determine_primer_type(
						$mrna->{coordinates}{'Alignment ' . $alignment},
						$mrna->{designed_primers}{'Primer Pair ' . $primer_pair},
						$self->intron_size
					);
					if ( $primer_type eq 'Intra-Exon Primers' ) {
						if ( $intra_exon_primer_number < $self->number_per_type ) {
							push(@$mapped_primers, $self->_create_insert_statement($mapped_primer, $mrna));
							$intra_exon_primer_number++;
						}
					} elsif ( $primer_type eq 'Junction Spanning Primers' ) {
						if ( $junction_primer_number < $self->number_per_type ) {
							push(@$mapped_primers, $self->_create_insert_statement($mapped_primer, $mrna));
							$junction_primer_number++;
						}
					} elsif ( $primer_type =~ /^Exon Primer Pair/ ) {
						if ( $exon_primer_number < $self->number_per_type ) {
							push(@$mapped_primers, $self->_create_insert_statement($mapped_primer, $mrna));
							$exon_primer_number++;
						}	
					} elsif ( $primer_type =~ /^Smaller Exon Primer Pair/ ) {
						if ( $smaller_exon_primer_number < $self->number_per_type ) {
							push(@$mapped_primers, $self->_create_insert_statement($mapped_primer, $mrna));
							$smaller_exon_primer_number++;
						}
					}
				}
			}
		}
	}
	return $mapped_primers;
}

=head2 _determine_primer_type

This subroutine is passed the intron/exon coordinates, the primer information, and 
the minimum intron size desired. It determines the positions of each primer relative
to intron-exon junctions and returns this information to the map subroutine.

=cut

sub _determine_primer_type {
	my ($self, $alignment, $primer_pair, $intron_size) = @_;
	# Pre-declare a string to hold the type of primers assigned to this primer pair
	my $primer_pair_type = '';
	# Extract the left primer coordinates from the primer_pair Hash Ref
	my $left_primer_coordinates = $primer_pair->{'Left Primer Coordinates'};
	# Extract the five prime position and the length of the left primer
	my ($left_primer_5prime, $left_primer_length) = split(/,/, $left_primer_coordinates);
	# Determine the three prime position of the left primer by adding the length
	my $left_primer_3prime = $left_primer_5prime + $left_primer_length;
	# Store the primer coordinates back in the primer Hash Ref
	$primer_pair->{left_primer_five_prime} = $left_primer_5prime;
	$primer_pair->{left_primer_three_prime} = $left_primer_3prime;
	$primer_pair->{left_primer_length} = $left_primer_length;
	# Extract the right primer coordinates from the primer_pair Hash Ref
	my $right_primer_coordinates = $primer_pair->{'Right Primer Coordinates'};
	# Extract the five prime position and the length of the right primer
	my ($right_primer_5prime, $right_primer_length) = split(/,/, $right_primer_coordinates);
	# Calculate the three prime position of the right primer by subtracting the
	# primer length
	my $right_primer_3prime = $right_primer_5prime - $right_primer_length;
	# Store the primer coordinates back in the primer Hash Ref
	$primer_pair->{right_primer_five_prime} = $right_primer_5prime;
	$primer_pair->{right_primer_three_prime} = $right_primer_3prime;
	$primer_pair->{right_primer_length} = $right_primer_length;
	# Use the private subroutine _determine_primer_position to determine the position
	# of each primer
	my $left_primer_position	= $self->_determine_primer_position($alignment, $left_primer_5prime, $left_primer_3prime, 'forward');
	$primer_pair->{'Left Primer Position'} = $left_primer_position;
	my $right_primer_position	= $self->_determine_primer_position($alignment, $right_primer_5prime, $right_primer_3prime, 'reverse');
	$primer_pair->{'Right Primer Position'} = $right_primer_position;
	# Ensure that both primer pairs have been defined, it is possible that one primer
	# will not b defined because of it's overlap of a junction, but not having enough
	# overlap on each side of the junction
	if ( $left_primer_position && $right_primer_position ) {
		# If the primers fall in the same exon, they are Intra-Exon Primers
		if ( $left_primer_position eq $right_primer_position ) {
			$primer_pair_type = 'Intra-Exon Primers';
			$primer_pair->{'Primer Pair Type'} = 'Intra-Exon Primers';
		# If either of the primers is a junction spanning primer, then the pair is
		# deemed to be Junction Spanning Primers
		} elsif (( $left_primer_position =~ /^Junction/ ) || ( $right_primer_position =~ /^Junction/ ) ) {
			$primer_pair_type = 'Junction Spanning Primers';
			$primer_pair->{'Primer Pair Type'} = 'Junction Spanning Primers';
		# If the primers are in different exons, determine the size of the sum of
		# the introns between the exons
		} else {
			# Pre-declare two integers to hold the integer value of the exon for
			# each primer
			my $left_primer_exon = 0;
			my $right_primer_exon = 0;
			if ( $left_primer_position =~ /^Inside of Exon (\d+)$/ ) {
				$left_primer_exon = $1;
			}
			if ( $right_primer_position =~ /^Inside of Exon (\d+)$/ ) {
				$right_primer_exon = $1;
			}
			# Make sure that the exon numbers for each primer have been defined
			# before proceeding
			if (($left_primer_exon > 0) &&
				($right_primer_exon > 0) ) {
				# Pre-declare an integer to hold the value for the sum of all of
				# the introns between the primers
				my $intron_sum = 0;
				# Iterate from the left primer exon to the right primer exon, adding the
				# size of each intron between the two exons to the intron sum
				for ( my $intron = $left_primer_exon; $intron < $right_primer_exon; $intron++ ) {
					$intron_sum += $alignment->{'Intron ' . $intron}{'Size'};
				}
				if ($intron_sum >= $intron_size) {
					$primer_pair_type = 'Exon Primer Pair';
					$primer_pair->{'Primer Pair Type'} = "Exon Primer Pair: $intron_sum" . "bp";
				} elsif ( $intron_sum < $intron_size ) {
					$primer_pair_type = 'Smaller Exon Primer Pair';
					$primer_pair->{'Primer Pair Type'} = "Smaller Exon Primer Pair: $intron_sum" . "bp";
				}
			}
		}
	}
	return ($primer_pair_type, $primer_pair);
}

=head2 _determine_primer_position

This private subroutine is passed the current alignment, the
coordinate string of the current primer being examined, and the
orientation of the primer relative to the transcriptional start
site. This subroutine then determine which exon the primer resides
in, or if the primer is an exon spanning primer that satisfies the
minimum 5' and 3' overhang requirements. The subroutine returnes
a string describing the position of the primer to the calling 
subroutine.

=cut

sub _determine_primer_position { 
	my ($self, $alignment, $five_prime, $three_prime, $direction) = @_;
	# Pre-declare a string to hold the position of the primer
	my $primer_position = '';
	# Iterate through the exons, determining if and then how the primer
	# is located relative to the 5'- and 3'-coordinates of the exon
	for (my $exon = 1; $exon <= $alignment->{'Number of Exons'}; $exon++) {
		# Depending on whether the primer is the left (forward) or right
		# (reverse) the math used to determine the primer position will
		# be different
		if ( $direction eq 'forward' ) {
			# If both the 5'-end of the primer greater than the 5'-end of the exon and
			# the 3'-end of the primer is less than the 3'-end of the exon, then the
			# primer is within the exon
			if (($alignment->{'Exon ' . $exon}{'mRNA'}{'Start'} <= $five_prime) && 
				($alignment->{'Exon ' . $exon}{'mRNA'}{'End'}	 >= $three_prime) ) {
				$primer_position = 'Inside of Exon ' . $exon;
			# If both ends of the primer are not located within the exon, test to see
			# if the primer spans the junction with the next exon
			} elsif (($alignment->{'Exon ' . $exon}{'mRNA'}{'End'} >= $five_prime) && 
					($alignment->{'Exon ' . $exon}{'mRNA'}{'End'} <= $three_prime) ) {
				# If the primer overlaps the current exon by at least 7bp and the next
				# exon by at least 4bp, then the primer is an exon junction primer
				if ((($alignment->{'Exon ' . $exon}{'mRNA'}{'End'} - $five_prime) > 7 ) &&
					(($three_prime - $alignment->{'Exon ' . $exon}{'mRNA'}{'End'}) > 4)) {
					$primer_position = 'Junction of Exons ' . $exon . ' and ' . ($exon+1);
				}
			}
		} elsif ( $direction eq 'reverse' ) {
			# If both the 5'-end of the primer greater than the 5'-end of the exon and
			# the 3'-end of the primer is less than the 3'-end of the exon, then the
			# primer is within the exon
			if (($alignment->{'Exon ' . $exon}{'mRNA'}{'Start'} <= $three_prime) && 
				($alignment->{'Exon ' . $exon}{'mRNA'}{'End'}	 >= $five_prime) ) {
				$primer_position = 'Inside of Exon ' . $exon;
			# If both ends of the primer are not located within the exon, test to see
			# if the primer spans the junction with the next exon
			} elsif (($alignment->{'Exon ' . $exon}{'mRNA'}{'End'} >= $three_prime) && 
					($alignment->{'Exon ' . $exon}{'mRNA'}{'End'} <= $five_prime) ) {
				# If the primer overlaps the next exon by at least 7bp and the current
				# exon by at least 4bp, then the primer is an exon junction primer
				if ((($alignment->{'Exon ' . $exon}{'mRNA'}{'End'} - $three_prime) > 4 ) &&
					(($five_prime - $alignment->{'Exon ' . $exon}{'mRNA'}{'End'}) > 7)) {
					$primer_position = 'Junction of Exons ' . $exon . ' and ' . ($exon+1);
				}
			}
		}
	}
	return $primer_position;
}

=head2 _create_insert_statment

This subroutine is used to modify the keys of the mapped primer Hash Ref so
that the Hash Ref can be used as an entry statement into the SQLite database

=cut

sub _create_insert_statement {
	my ($self, $mapped_primer, $mrna) = @_;
	# Create a Hash Ref to hold the primer pair information
	my $insert_statement = {
		accession					=>	$mrna->{mrna},
		description					=>	$mrna->{description},
		primer_pair_type			=>	$mapped_primer->{'Primer Pair Type'},
		primer_pair_penalty			=>	$mapped_primer->{'Product Penalty'},
		left_primer_position		=>	$mapped_primer->{'Left Primer Position'},
		right_primer_position		=>	$mapped_primer->{'Right Primer Position'},
		product_size				=>	$mapped_primer->{'Product Size'},
		left_primer_sequence		=>	$mapped_primer->{'Left Primer Sequence'},
		right_primer_sequence		=>	$mapped_primer->{'Right Primer Sequence'},
		left_primer_length			=>	$mapped_primer->{'left_primer_length'},
		right_primer_length			=>	$mapped_primer->{'right_primer_length'},
		left_primer_tm				=>	$mapped_primer->{'Left Primer Tm'},
		right_primer_tm				=>	$mapped_primer->{'Right Primer Tm'},
		left_primer_five_prime		=>	$mapped_primer->{'left_primer_five_prime'},
		left_primer_three_prime		=>	$mapped_primer->{'left_primer_three_prime'},
		right_primer_five_prime		=>	$mapped_primer->{'right_primer_five_prime'},
		right_primer_three_prime	=>	$mapped_primer->{'right_primer_three_prime'},
	};
	return $insert_statement;
}

__PACKAGE__->meta->make_immutable;

1;
