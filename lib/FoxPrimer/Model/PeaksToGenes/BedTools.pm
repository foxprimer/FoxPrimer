package FoxPrimer::Model::PeaksToGenes::BedTools;
use Moose;
use namespace::autoclean;
use Data::Dumper;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::PeaksToGenes::BedTools - Catalyst Model

=head1 DESCRIPTION

This Module provides the bulk of the business logic for FoxPrimer::PeaksToGenes.

Using intersectBed this module determines the position of the designed 
ChIP primer pair relative to the transcriptional start site of transcripts
within 100Kb.

=head1 AUTHOR

Jason R Dobson,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

sub annotate_peaks {
	my ($self, $summits_file, $index_files, $intersect_bed_executable) = @_;
	my $return;
	my $indexed_peaks = $self->_create_blank_index($index_files);
	foreach my $index_file (@$index_files) {
		my $location;
		if ($index_file =~ /_Index\/(.+?)\.bed$/ ) {
			$location = $1;
		}
		if ($location) {
			my $peak_number = $location;
			my @intersected_peaks = `$intersect_bed_executable -wb -a $summits_file -b $index_file`;
			foreach my $intersected_peak (@intersected_peaks) {
				chomp ($intersected_peak);
				my ($summit_chr, $summit_start, $summit_end, $summit_name,
					$index_chr, $index_start, $index_stop, $index_name, $index_score,
					$index_strand) = split(/\t/, $intersected_peak);
				my $index_gene;
				if ($index_name =~ /^(\w\w_\d+?)_/) {
					$index_gene = $1;
				}
				if ( $index_gene ) {
					push(@{$indexed_peaks->{$index_gene}{$peak_number}}, $summit_name);
				} else {
					die "\n\nCould not extract a RefSeq accession from $index_name.\n\n";
				}
			}
		} else {
			die "\n\nThere was a problem determining the location of the index file relative to transcription start site\n\n";
		}
	}
	return $indexed_peaks;
}

sub _create_blank_index {
	my ($self, $index_files) = @_;
	my $indexed_peaks;
	my $genes;
	foreach my $index_file (@$index_files) {
		if ($index_file =~ /Promoters/) {
			open my($promoters), "<", $index_file or die "Could not open $index_file $! \n";
			while (<$promoters>) {
				my $line = $_;
				chomp ($line);
				my ($chr, $start, $stop, $name, $rest_of_line) = split(/\t/, $line);
				if ( $name =~ /^(\w\w_\d+?)_/ ) {
					push (@$genes, $1);
				}
			}
		}
	}
	foreach my $index_file (@$index_files) {
		foreach my $gene (@$genes) {
			my $index_base;
			if ($index_file =~ /.+?\/.+?_Index\/(.+?)\.bed$/ ) {
				$index_base = $1;
			}
			my $peak_numbers = $index_base;
			$indexed_peaks->{$gene}{$peak_numbers} = [];
		}
	}
	return $indexed_peaks;
}

__PACKAGE__->meta->make_immutable;

1;
