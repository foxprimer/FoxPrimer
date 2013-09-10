package FoxPrimer::Model::PeaksToGenes;
use Moose;
use Carp;
use namespace::autoclean;
use FindBin;
use lib "$FindBin::Bin/../lib";

with 'FoxPrimer::Model::PeaksToGenes::FileStructure';
with 'FoxPrimer::Model::PeaksToGenes::BedTools';

=head1 NAME

FoxPrimer::Model::PeaksToGenes

=head1 DESCRIPTION

This is a special version of the PeaksToGenes algorithm, designed specifically
for FoxPrimer to determine the positions of ChIP primer pairs relative to genes.

=head1 AUTHOR

Jason R Dobson, L<foxprimer@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

=head2 genome

This Moose attribute holds the genome string that the primers will be mapped
against. This attribute must be defined when creating an instance of this class.

=cut

has genome	=>	(
	is			=>	'ro',
	isa			=>	'Str',
    required    =>  1,
    lazy        =>  1,
    default     =>  sub {
        croak "\n\nYou must define a genome string.\n\n";
    }
);

=head2 primers

This Moose attribute holds a Hash Ref of primers to map. This attribute must be
defined when creating an instance of this class.

=cut

has primers	=>	(
	is			=>	'ro',
	isa			=>	'HashRef',
    required    =>  1,
    lazy        =>  1,
    default     =>  sub {
        "\n\nYou must define a data structure of primers.\n\n";
    }
);

=head2 target_coordinates

This Moose attribute holds the coordinates in Hash Ref format that define where
the target sequence for primer design maps to the user-defined genome. This
attribute must be defined when creating an instance of this class.

=cut

has target_coordinates  =>  (
    is          =>  'ro',
    isa         =>  'HashRef',
    required    =>  1,
    lazy        =>  1,
    default     =>  sub {
        croak "\n\nYou must define the coordinates for the target sequnce.\n\n";
    }
);

=head2 chromosome_sizes

This Moose attribute holds a Hash Ref of the chromosome sizes for the
user-defined genome. This attribute must be defined with creating an instance of
this class.

=cut

has chromosome_sizes    =>  (
    is          =>  'ro',
    isa         =>  'HashRef',
    required    =>  1,
    lazy        =>  1,
    default     =>  sub {
        croak "\n\nYou must set a chromosome sizes Hash Ref.\n\n";
    }
);

=head2 annotate_primer_pairs

This module controls the logic flow to determine the locations of designed ChIP
primer pairs relative to all transcripts in the user-defined genome.

=cut

sub annotate_primer_pairs {
	my $self = shift;

	# Retreive the index file based on the genome by running the 'get_index'
    # subroutine consumed from the FoxPrimer::Model::PeaksToGenes::FileStructure
    # role.
	my $index_file = $self->get_index(
        $self->genome,
        $self->chromosome_sizes,
    );

    # Run the primers_to_bed subroutine consumed form
    # FoxPrimer::Model::PeaksToGenes::BedTools to return a File::Temp object
    # that corresponds to a sorted BED-format file of primer pair coordinates
    my $primer_index_file = $self->primers_to_bed(
        $self->primers,
        $self->target_coordinates,
    );

    # Run the annotate_primers subroutine consumed from
    # FoxPrimer::Model::PeaksToGenes::BedTools to return a Hash Ref of
    # information about genes close to primer pairs designed.
    my $primers_to_genes_hash = $self->annotate_primers(
        $index_file,
        $primer_index_file,
    );

    return $primers_to_genes_hash;
}

__PACKAGE__->meta->make_immutable;

1;
