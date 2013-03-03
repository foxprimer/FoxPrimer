package FoxPrimer::Model::PrimerDesign::chipPrimerDesign::FIMO;
use Moose;
use namespace::autoclean;
use FindBin;
use File::Which;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::PrimerDesign::chipPrimerDesign::FIMO - Catalyst Model

=head1 DESCRIPTION

This Module runs FIMO to search for the user-defined motif in the
user-defined FASTA format.

=head1 AUTHOR

Jason R Dobson foxprimer@gmail.com

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 fasta_file

This Moose object holds the string for the location of the FASTA file to
search for motifs in.

=cut

has fasta_file	=>	(
	is			=>	'ro',
	isa			=>	'Str',
);

=head2 motif

This Moose object holds the user-defined pre-validated motif name to search
for in the FASTA file.

=cut

has motif	=>	(
	is			=>	'ro',
	isa			=>	'Str',
);

=head2 _motif_file

This Moose object holds the path to the MEME-format motif file.

=cut

has _motif_file	=>	(
	is			=>	'ro',
	isa			=>	'Str',
	required	=>	1,
	lazy		=>	1,
	default		=>	sub {
		my $self = shift;
		my $motif_file = "$FindBin::Bin/../root/static/meme_motifs/" .
		$self->motif . ".meme";
		if ( -r $motif_file ) {
			return $motif_file;
		} else {
			return '';
		}
	},
	reader		=>	'motif_file',
);

=head2 find_motifs

This subroutine 

=cut

__PACKAGE__->meta->make_immutable;

1;
