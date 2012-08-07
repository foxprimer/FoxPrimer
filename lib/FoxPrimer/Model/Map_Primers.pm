package FoxPrimer::Model::Map_Primers;
use Moose;
use namespace::autoclean;
use Data::Dumper;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::Map_Primers - Catalyst Model

=head1 DESCRIPTION

This module provides the business logic to intersect
the intron-exon coordinates with primer locations to
determine the type of primer pair based on location.

=head1 AUTHOR

Jason R Dobson,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 map_primers

This subroutine is given the coordinates hash reference, the extracted
primer pair information, and the integer value of the number of each type
of primer pair to store in the database and return to the user.

=cut

sub map_primers {
	my ($self, $coordinates, $primers, $number_to_make, $intron_size) = @_;
	my $mapped_primers;
	my $alignment_number = $coordinates->{'Number of Alignments'};
	for ( my $alignment = 1; $alignment <= $alignment_number; $alignment++ ) {
		my $junction_primer_number = 0; 
		my $exon_primer_number = 0; 
		my $smaller_exon_primer_number = 0;
		my $intra_exon_primer_number = 0;
		for ( my $primer_pair = 0; $primer_pair < $primers->{'Number of Primers'}; $primer_pair++ ) {
			if ( ($junction_primer_number 		< $number_to_make) || ($exon_primer_number 			< $number_to_make) || ($intra_exon_primer_number		< $number_to_make) || ($smaller_exon_primer_number	< $number_to_make) ) {
				my ($primer_type, $mapped_primer) = $self->_determine_primer_type($coordinates->{'Alignment ' . $alignment}, $primers->{'Primer Pair ' . $primer_pair}, $intron_size);
				if ( $primer_type eq 'Intra-Exon Primers' ) {
					if ( $intra_exon_primer_number < $number_to_make ) {
						$mapped_primers->{'Primer Pair ' . $primer_pair} = $mapped_primer;
						$intra_exon_primer_number++;
					}
				} elsif ( $primer_type eq 'Junction Spanning Primers' ) {
					if ( $junction_primer_number < $number_to_make ) {
						$mapped_primers->{'Primer Pair ' . $primer_pair} = $mapped_primer;
						$junction_primer_number++;
					}
				} elsif ( $primer_type eq 'Exon Primer Pair' ) {
					if ( $exon_primer_number < $number_to_make ) {
						$mapped_primers->{'Primer Pair ' . $primer_pair} = $mapped_primer;
						$exon_primer_number++;
					}	
				} elsif ( $primer_type eq 'Smaller Exon Primer Pair' ) {
					if ( $smaller_exon_primer_number < $number_to_make ) {
						$mapped_primers->{'Primer Pair ' . $primer_pair} = $mapped_primer;
						$smaller_exon_primer_number++;
					}
				}
			}
		}
	}
	return $mapped_primers;
}

=head2 _determine_primer_type

This private subroutine is given the alignment and the primer pair information
and then determines the positions of the primers relative to alignment and classifies
the primer pair, returning the information back to the main loop.

=cut

sub _determine_primer_type {
	my ($self, $alignment, $primer_pair, $intron_size) = @_;
	my $primer_pair_type;
	my $left_primer_coordinates = $primer_pair->{'Left Primer Coordinates'};
	my ($left_primer_5prime, $left_primer_length) = split(/,/, $left_primer_coordinates);
	my $left_primer_3prime = $left_primer_5prime + $left_primer_length;
	my $right_primer_coordinates = $primer_pair->{'Right Primer Coordinates'};
	my ($right_primer_3prime, $right_primer_length) = split(/,/, $right_primer_coordinates);
	my $right_primer_5prime = $right_primer_3prime - $right_primer_length;
	my $left_primer_position	= $self->_determine_primer_position($alignment, $left_primer_5prime, $left_primer_3prime, 'forward');
	$primer_pair->{'Left Primer Position'} = $left_primer_position;
	my $right_primer_position	= $self->_determine_primer_position($alignment, $right_primer_5prime, $right_primer_3prime, 'reverse');
	$primer_pair->{'Right Primer Position'} = $right_primer_position;
	if ( $left_primer_position eq $right_primer_position ) {
		$primer_pair_type = 'Intra-Exon Primers';
		$primer_pair->{'Primer Pair Type'} = 'Intra-Exon Primers';
	} elsif (( $left_primer_position =~ /^Junction/ ) || ( $right_primer_position =~ /^Junction/ ) ) {
		$primer_pair_type = 'Junction Spanning Primers';
		$primer_pair->{'Primer Pair Type'} = 'Junction Spanning Primers';
	} else {
		my ($left_primer_exon, $right_primer_exon);
		if ( $left_primer_position =~ /^Inside of Exon (\d+)$/ ) {
			$left_primer_exon = $1;
		}
		if ( $right_primer_position =~ /^Inside of Exon (\d+)$/ ) {
			$right_primer_exon = $1;
		}
		my $intron_sum;
		for ( my $intron = $left_primer_exon; $intron < $right_primer_exon; $intron++ ) {
			$intron_sum += $alignment->{'Intron ' . $intron}{'Size'};
		}
		if ($intron_sum >= $intron_size) {
			$primer_pair_type = 'Exon Primer Pair';
			$primer_pair->{'Primer Pair Type'} = 'Exon Primer Pair';
			$primer_pair->{'Sum of Introns Size'} = $intron_sum;
		} elsif ( $intron_sum < $intron_size ) {
			$primer_pair_type = 'Smaller Exon Primer Pair';
			$primer_pair->{'Primer Pair Type'} = 'Smaller Exon Primer Pair';
			$primer_pair->{'Sum of Introns Size'} = $intron_sum;
		}
	}
	if ( ! $primer_pair_type ) {
		$primer_pair_type = 'Error: Undefined!';
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
	my $primer_position;
	my $number_of_exons = $alignment->{'Number of Exons'};
	for (my $exon = 1; $exon <= $number_of_exons; $exon++) {
		if ( ($alignment->{'Exon ' . $exon}{'mRNA'}{'Start'} <= $five_prime) && ($alignment->{'Exon ' . $exon}{'mRNA'}{'End'}	 >= $three_prime) ) {
			$primer_position = 'Inside of Exon ' . $exon;
		} elsif ( ($alignment->{'Exon ' . $exon}{'mRNA'}{'Start'} >= $five_prime) && ($alignment->{'Exon ' . $exon}{'mRNA'}{'Start'} <= $three_prime) ) {
			my ($delta_left, $delta_right);
			if ( $direction eq 'forward' ) {
				$delta_left = $alignment->{'Exon ' . $exon}{'mRNA'}{'Start'} - $five_prime;
				$delta_right = $three_prime - $alignment->{'Exon ' . $exon}{'mRNA'}{'Start'};
			} elsif ( $direction eq 'reverse' ) {
				$delta_left =  $three_prime - $alignment->{'Exon ' . $exon}{'mRNA'}{'Start'};
				$delta_right = $alignment->{'Exon ' . $exon}{'mRNA'}{'Start'} - $five_prime;
			}
			if ( ($delta_left > 7) && ($delta_right > 4) ) {
				$primer_position = 'Junction of Exons ' . ($exon-1) . ' and ' . $exon;
			} elsif ( $delta_left > $delta_right ) {
				$primer_position = 'Inside of Exon ' . ($exon-1);
			} elsif ( $delta_right > $delta_left ) {
				$primer_position = 'Inside of Exon ' . $exon;
			}
		}
	}
	return $primer_position;
}
__PACKAGE__->meta->make_immutable;

1;
