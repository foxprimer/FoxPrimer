package FoxPrimer::Model::PeaksToGenes::FileStructure;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::PeaksToGenes::FileStructure - Catalyst Model

=head1 DESCRIPTION

This module provides a subroutine, which takes the genome as an
argument and returns an Array Ref of file locations for each
index.

=head1 AUTHOR

Jason R Dobson,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

my $human_index = [                 
	"root/static/files/Human_Index/Human_100K_Upstream.bed",
	"root/static/files/Human_Index/Human_50K_Upstream.bed",
	"root/static/files/Human_Index/Human_25K_Upstream.bed",
	"root/static/files/Human_Index/Human_10K_Upstream.bed",
	"root/static/files/Human_Index/Human_5K_Upstream.bed",
	"root/static/files/Human_Index/Human_Promoters.bed",
	"root/static/files/Human_Index/Human_5Prime_UTR.bed",
	"root/static/files/Human_Index/Human_Exons.bed",
	"root/static/files/Human_Index/Human_Introns.bed",
	"root/static/files/Human_Index/Human_3Prime_UTR.bed",
	"root/static/files/Human_Index/Human_2.5K_Downstream.bed",
	"root/static/files/Human_Index/Human_5K_Downstream.bed",
	"root/static/files/Human_Index/Human_10K_Downstream.bed",
	"root/static/files/Human_Index/Human_25K_Downstream.bed",
	"root/static/files/Human_Index/Human_50K_Downstream.bed",
	"root/static/files/Human_Index/Human_100K_Downstream.bed",
];

my $mouse_index = [                 
	"root/static/files/Mouse_Index/Mouse_100K_Upstream.bed",
	"root/static/files/Mouse_Index/Mouse_50K_Upstream.bed",
	"root/static/files/Mouse_Index/Mouse_25K_Upstream.bed",
	"root/static/files/Mouse_Index/Mouse_10K_Upstream.bed",
	"root/static/files/Mouse_Index/Mouse_5K_Upstream.bed",
	"root/static/files/Mouse_Index/Mouse_Promoters.bed",
	"root/static/files/Mouse_Index/Mouse_5Prime_UTR.bed",
	"root/static/files/Mouse_Index/Mouse_Exons.bed",
	"root/static/files/Mouse_Index/Mouse_Introns.bed",
	"root/static/files/Mouse_Index/Mouse_3Prime_UTR.bed",
	"root/static/files/Mouse_Index/Mouse_2.5K_Downstream.bed",
	"root/static/files/Mouse_Index/Mouse_5K_Downstream.bed",
	"root/static/files/Mouse_Index/Mouse_10K_Downstream.bed",
	"root/static/files/Mouse_Index/Mouse_25K_Downstream.bed",
	"root/static/files/Mouse_Index/Mouse_50K_Downstream.bed",
	"root/static/files/Mouse_Index/Mouse_100K_Downstream.bed",
];

=head2 get_index

This subroutine is called by the Model FoxPrimer::Peaks to genes and
returns an Array Reference of index file paths.

=cut

sub get_index {
	my ($self, $genome) = @_;
	if ( $genome eq 'hg19' ) {
		return $self->_can_open_files($human_index);
	} elsif ( $genome eq 'mm9' ) {
		return $self->_can_open_files($mouse_index);
	} else {
		die "\n\nThere was a problem in the get_index subroutine returning the proper index of genomic locations.\n\n";
	}
}

=head2 _can_open_files

This is a private subroutine that is called to ensure that the index files can be opened.

=cut

sub _can_open_files {
	my ($self, $index_files) = @_;
	foreach my $index_file (@$index_files) {
		die "\n\nCould not read from required index file: $index_file\n\n" unless (-r $index_file);
	}
	return $index_files;
}

__PACKAGE__->meta->make_immutable;

1;
