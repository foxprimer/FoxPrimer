package FoxPrimer::Model::Create_Fasta_Files;
use Moose;
use namespace::autoclean;
use Bio::SeqIO;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::Create_Fasta_Files - Catalyst Model

=head1 DESCRIPTION

Given the rna or dna object from FoxPrimer::Model::mRNA_Primer_Design
this module will extract the sequence from these objects into Fasta
format, and write the fasta sequence out to a temporary file for
Sim4 and Primer3.

=head1 AUTHOR

Jason R Dobson,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 write_to_fasta

This subroutine takes the accession, mrna, and genomic objects as arguments
and writes the mrna and genomic objects to file defined by the accession.
The filename for the mrna and dna are returned to FoxPrimer::Model::mRNA_Primer_Design

=cut

sub write_to_fasta {
	my ($self, $accession, $rna_object, $dna_object) = @_;
	my $rna_fh = $accession . '.mRNA.fa';
	my $dna_fh = $accession . '.dna.fa';
	$self->_fasta_io($rna_object, $rna_fh);
	$self->_fasta_io($dna_object, $dna_fh);
	return ( $rna_fh, $dna_fh );
}

=head2 _fasta_io

This private subroutine writes the sequence to file.

=cut

sub _fasta_io {
	my ($self, $sequence_object, $file_handle) = @_;
	my $seqout = Bio::SeqIO->new(
		-file	=>	">$file_handle",
		-format	=>	'Fasta',
	);
	$seqout->write_seq($sequence_object);
}

__PACKAGE__->meta->make_immutable;

1;
