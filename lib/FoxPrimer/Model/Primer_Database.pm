package FoxPrimer::Model::Primer_Database;
use Moose;
use namespace::autoclean;
use Data::Dumper;
use FoxPrimer::Schema;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::Primer_Database - Catalyst Model

=head1 DESCRIPTION

This module prepares an array reference of array references
of the information for each primer pair.

=head1 AUTHOR

Jason R Dobson,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 prepare_insert_lines

This subroutine prepares lines to be inserted by the controller into
the primer database.

=cut

sub prepare_insert_lines {
	my ($self, $mapped_primers, $description, $rna_accession) = @_;
	foreach my $primer_pair ( keys %$mapped_primers ) {
		my $primer_type_string;
		if ( ($mapped_primers->{$primer_pair}{'Primer Pair Type'} eq 'Smaller Exon Primer Pair') ||
			($mapped_primers->{$primer_pair}{'Primer Pair Type'} eq 'Exon Primer Pair') ) {
			$primer_type_string = 'Flanking Intron(s): ' . $mapped_primers->{$primer_pair}{'Sum of Introns Size'}
		} else {
			$primer_type_string = $mapped_primers->{$primer_pair}{'Primer Pair Type'};
		}
		my $schema = FoxPrimer::Schema->connect('dbi:SQLite:db/primers.db');
		my $result_class = $schema->resultset('Primer');
		$result_class->update_or_create(
			'primer_type'				=>	$primer_type_string,
			'description'				=>	$description,
			'mrna'						=>	$rna_accession,
			'primer_pair_number'		=>	$primer_pair,
			'left_primer_sequence'		=>	$mapped_primers->{$primer_pair}{'Left Primer Sequence'},
			'right_primer_sequence'		=>	$mapped_primers->{$primer_pair}{'Right Primer Sequence'},
			'left_primer_tm'			=>	$mapped_primers->{$primer_pair}{'Left Primer Tm'},
			'right_primer_tm'			=>	$mapped_primers->{$primer_pair}{'Right Primer Tm'},
			'left_primer_coordinates'	=>	$mapped_primers->{$primer_pair}{'Left Primer Coordinates'},
			'right_primer_coordinates'	=>	$mapped_primers->{$primer_pair}{'Right Primer Coordinates'},
			'product_size'				=>	$mapped_primers->{$primer_pair}{'Product Size'},
			'product_penalty'			=>	$mapped_primers->{$primer_pair}{'Product Penalty'},
			'left_primer_position'		=>	$mapped_primers->{$primer_pair}{'Left Primer Position'},
			'right_primer_position'		=>	$mapped_primers->{$primer_pair}{'Right Primer Position'},
		);
	}
}

__PACKAGE__->meta->make_immutable;

1;
