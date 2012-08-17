package FoxPrimer::Model::PeaksToGenes;
use Moose;
use namespace::autoclean;
use FoxPrimer::Model::PeaksToGenes::FileStructure;
use FoxPrimer::Model::PeaksToGenes::BedTools;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::PeaksToGenes - Catalyst Model

=head1 DESCRIPTION

This is the main Catalyst Model called by the Catalyst Controller.

This is a special version of the PeaksToGenes algorithm, designed
specifically for FoxPrimer to determine the positions of ChIP 
primer pairs relative to transcriptional start sites.

=head1 AUTHOR

Jason R Dobson,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 Moose declarations

This section is for the Moose declarations for objects that will be created
by the Catalyst Controller for each instance of FoxPrimer::PeaksToGenes.

=cut

has genome	=>	(
	is			=>	'ro',
	isa			=>	'Str',
);

has intersect_bed_executable	=>	(
	is			=>	'ro',
	isa			=>	'Str',
	default		=>	sub {
		my $self = shift;
		my $intersect_bed_path = `which intersectBed`;
		chomp ($intersect_bed_path);
		return $intersect_bed_path;
	},
	required	=>	1,
	lazy		=>	1,
);

has chromosome	=>	(
	is		=>	'rw',
	isa		=>	'Str',
);

has start	=>	(
	is		=>	'rw',
	isa		=>	'Int',
);

has stop	=>	(
	is		=>	'rw',
	isa		=>	'Int',
);

=head2 annotate_primer_pairs

This is the main subroutine called by the Catalyst controller.

This module controls the logic flow to determine the locations
of designed ChIP primer pairs relaive to the transcriptional
start sites of all transcripts.

=cut

sub annotate_primer_pairs {
	my $self = shift;
}

__PACKAGE__->meta->make_immutable;

1;
