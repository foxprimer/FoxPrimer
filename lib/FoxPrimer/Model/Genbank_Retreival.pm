package FoxPrimer::Model::Genbank_Retreival;
use Moose;
use namespace::autoclean;
use Bio::DB::GenBank;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::Genbank_Retreival - Catalyst Model

=head1 DESCRIPTION

This submodule interacts with NCBI Genbank to retrive
BioPerl objects for the mRNA and genomic DNA corresponding
to the user-entered gene. This module also extracts the
gene description.  All of these parameters are returned
to the mRNA_Primer_Design Model for further processing.

=head1 AUTHOR

Jason R Dobson,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 get_objects

This subroutine is called by FoxPrimer::Model::mRNA_Primer_Design
to interact with Genbank to retrieve mRNA and Genomic BioPerl
objects, as well as a gene description string.

=cut

sub get_objects {
	my ($self, $gis_and_coordinates) = @_;
	my ($mrna_accession, $mrna_gi, $dna_gi, $dna_start, $dna_stop,
		$orientation) = split(/\t/, $gis_and_coordinates);
	my $rna_bank = Bio::DB::GenBank->new();
	my $mrna_object = $rna_bank->get_Seq_by_gi($mrna_gi);
	my $description = $mrna_object->desc();
	my $strand;
	if ( $orientation eq '+' ) {
		$strand = 1;
	} elsif ( $orientation eq '-' ) {
		$strand = 2;
	}
	my $dna_bank = Bio::DB::GenBank->new(
		-format		=>	'Fasta',
		-seq_start	=>	$dna_start,
		-seq_stop	=>	$dna_stop,
		-strand		=>	$strand,
	);
	my $dna_object = $dna_bank->get_Seq_by_acc($dna_gi);
	return ($description, $mrna_object, $dna_object);
}

__PACKAGE__->meta->make_immutable;

1;
