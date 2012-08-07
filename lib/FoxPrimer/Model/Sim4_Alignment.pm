package FoxPrimer::Model::Sim4_Alignment;
use Moose;
use namespace::autoclean;
use Bio::Tools::Run::Alignment::Sim4;
use Data::Dumper;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::Sim4_Alignment - Catalyst Model

=head1 DESCRIPTION

This module uses the BioPerl interface to call Sim4
to align the mRNA sequence to the reference genomic
DNA sequence. Then, it determines the intron/exon
coordinates.

=head1 AUTHOR

Jason R Dobson,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 sim4_alignment

This subroutine is called by FoxPrimer::Model::mRNA_Primer_Design
to align mRNA to genomic DNA and determine the intron/exon boundaries
for each potential alignment.

=cut


sub sim4_alignment {
	my ($self, $rna, $dna) = @_;
	my $coordinates;
	my $sim4 = Bio::Tools::Run::Alignment::Sim4->new(
		cdna_seq	=>	$rna,
		genomic_seq	=>	$dna,
	);
	my @exon_sets = $sim4->align;
	my $alignment_iterator = 1;
	foreach my $set ( @exon_sets ) {
		my $exon_iterator = 1;
		foreach my $exon ( $set->sub_SeqFeature ) {
			$coordinates->{'Alignment ' . $alignment_iterator}{'Exon ' . $exon_iterator}{'Genomic'}{'Start'} = $exon->start;
			$coordinates->{'Alignment ' . $alignment_iterator}{'Exon ' . $exon_iterator}{'Genomic'}{'End'} = $exon->end;
			$coordinates->{'Alignment ' . $alignment_iterator}{'Exon ' . $exon_iterator}{'mRNA'}{'Start'} = $exon->est_hit->start;
			$coordinates->{'Alignment ' . $alignment_iterator}{'Exon ' . $exon_iterator}{'mRNA'}{'End'} = $exon->est_hit->end;
			$exon_iterator++;
		}
		$coordinates->{'Alignment ' . $alignment_iterator}{'Number of Exons'} = $exon_iterator-1;
		for ( my $intron_iterator = 1; $intron_iterator < ($exon_iterator-1); $intron_iterator++ ) {
			$coordinates->{'Alignment ' . $alignment_iterator}{'Intron ' . $intron_iterator}{'Size'} = $coordinates->{'Alignment ' . $alignment_iterator}{'Exon ' . ($intron_iterator+1)}{'Genomic'}{'Start'} - $coordinates->{'Alignment ' . $alignment_iterator}{'Exon ' . $intron_iterator}{'Genomic'}{'End'};
		}
		$alignment_iterator++;
	}
	$coordinates->{'Number of Alignments'} = $alignment_iterator - 1;
	return $coordinates;
}

__PACKAGE__->meta->make_immutable;

1;
