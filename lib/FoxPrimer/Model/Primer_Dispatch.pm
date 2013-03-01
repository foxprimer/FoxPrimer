package FoxPrimer::Model::Primer_Dispatch;
use Moose;
use namespace::autoclean;
use Data::Dumper;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::Primer_Dispatch - Catalyst Model

=head1 DESCRIPTION

This module accepts an array reference of potential NCBI accessions
and detemines whether these accessions are contained in the genes2accession
flat file from NCBI. If they are, a hash reference for RefSeq accession of
mRNA GI, genomic DNA GI, genomic DNA positions, and strand. If not, each 
RefSeq Accession is passed to an array reference to be returned to the user
informing them that the RefSeq accession was not found in the database.

=head1 AUTHOR

Jason R Dobson,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

has gene2accession	=>	(
	is			=>	'ro',
	isa			=>	'Str',
	default		=>	'root/static/gene2accession/gene2accession',
	required	=>	1,
);

sub check_accessions {
	my ($self, $accessions) = @_;
	my ($valid_accessions, $invalid_accessions);
	my $dispatch_fh = $self->gene2accession;
	foreach my $accession (@$accessions) {
		if ( $accession =~ /^\w\w_\d+/ ) {
			my $accession_root;
			if ( $accession =~ /^(\w\w_\d+)\./ ) {
				$accession_root = $1;
			} else {
				$accession_root = $accession;
			}
			my $potential_matches = `grep \'$accession_root\' $dispatch_fh`;
			if ( $potential_matches ) {
				my @potential_match_lines = split(/\n/, $potential_matches);
				foreach my $potential_match_line (@potential_match_lines) {
					chomp ($potential_match_line);
					my ($tax_id, $gene_id, $status, $rna_accession, $rna_gi, $protein_accession,
						$protein_gi, $genomic_accession, $genomic_gi, $genomic_start, $genomic_stop,
						$orientation, $assembly) = split (/\t/, $potential_match_line);
					if ( $rna_accession 			&& 
						$rna_gi 		=~ /\d+/	&& 
						$genomic_gi		=~ /\d+/	&&
						$genomic_start	=~ /\d+/	&&
						$genomic_stop	=~ /\d+/	&&
						($orientation eq '+' || $orientation eq '-') &&
						$assembly 		=~ /^Reference/) {
						my $rna_accession_root;
						if ( $rna_accession =~ /^(\w\w_\d+?)\./ ) {
							$rna_accession_root = $1;
						} else {
							$rna_accession_root = $rna_accession;
						}
						if ($accession_root eq $rna_accession_root) {
							push (@{$valid_accessions->{$accession}}, join("\t", $rna_accession, $rna_gi, $genomic_gi,
									$genomic_start, $genomic_stop, $orientation));
						}
					} 
				}
			} else {
				push (@$invalid_accessions, $accession);
			}
		} else {
			push (@$invalid_accessions, $accession);
		}
	}
	foreach my $accession ( @$accessions ) {
		if ( defined ( $valid_accessions->{$accession} ) ) {
			my $accessions_and_coordinates = $valid_accessions->{$accession};
			my $unique_accessions_and_coordinates = $self->_get_unique ( $accessions_and_coordinates );
			$valid_accessions->{$accession} = $unique_accessions_and_coordinates;
		} else {
			push ( @$invalid_accessions, $accession );
		}
	}
	return ($valid_accessions, $invalid_accessions);
}

sub _get_unique {
	my ($self, $array) = @_;
	my ($return, $seen);
	foreach my $item (@$array) {
		unless ( defined ( $seen->{$item} ) ) {
			$seen->{$item} = 1;
			push (@$return, $item);
		}
	}
	return $return;
}

__PACKAGE__->meta->make_immutable;

1;
