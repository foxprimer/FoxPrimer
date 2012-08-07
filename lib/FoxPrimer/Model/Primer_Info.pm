package FoxPrimer::Model::Primer_Info;
use Moose;
use namespace::autoclean;
use Bio::Tools::Primer3;
use Data::Dumper;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::Primer_Info - Catalyst Model

=head1 DESCRIPTION

This module utilizes Bio::Tools::Primer3 to extract the primer pairs
and relevant information from the temporary file created by Primer3.
The results are returned to FoxPrimer::Model::mRNA_Primer::Design as
a HashRef of primer pairs.

=head1 AUTHOR

Jason R Dobson,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 extract_primer_pairs

This subroutine is called by FoxPrimer::Model::mRNA_Primer::Design to
extract the primer information to be annotated later.

=cut

sub extract_primer_pairs {
	my $self = shift;
	my $primer3 = Bio::Tools::Primer3->new(
		-file	=>	"temp.out",
	);
	my $primers;
	my $number_of_primers = $primer3->number_of_results;
	$primers->{'Number of Primers'} = $number_of_primers;
	for (my $i = 0; $i < $number_of_primers; $i++) {
		my $temp_result = $primer3->primer_results($i);
			$primers->{'Primer Pair ' . $i}{'Left Primer Coordinates'} = $temp_result->{PRIMER_LEFT};
			$primers->{'Primer Pair ' . $i}{'Right Primer Coordinates'} = $temp_result->{PRIMER_RIGHT};
			$primers->{'Primer Pair ' . $i}{'Left Primer Sequence'} = $temp_result->{PRIMER_LEFT_SEQUENCE};
			$primers->{'Primer Pair ' . $i}{'Right Primer Sequence'} = $temp_result->{PRIMER_RIGHT_SEQUENCE};
			$primers->{'Primer Pair ' . $i}{'Left Primer Tm'} = $temp_result->{PRIMER_LEFT_TM};
			$primers->{'Primer Pair ' . $i}{'Right Primer Tm'} = $temp_result->{PRIMER_RIGHT_TM};
			$primers->{'Primer Pair ' . $i}{'Product Size'} = $temp_result->{PRIMER_PAIR_PRODUCT_SIZE};
			$primers->{'Primer Pair ' . $i}{'Product Penalty'} = $temp_result->{PRIMER_PAIR_PENALTY};
	}
	return $primers;
}

__PACKAGE__->meta->make_immutable;

1;
