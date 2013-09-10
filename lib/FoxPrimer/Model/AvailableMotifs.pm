package FoxPrimer::Model::AvailableMotifs;
use Moose::Role;
use Carp;
use namespace::autoclean;
use FindBin;
use lib "$FindBin::Bin/../lib";
use autodie;

=head1 NAME

FoxPrimer::Model::AvailableMotifs

=head1 DESCRIPTION

This part of the business model dynamically returns to the user a list of
available motifs found in the 'root/static/meme_motifs/' folder.

=head1 AUTHOR

Jason R Dobson, L<foxprimer@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

=head2 motifs_file

This Moose attribute holds the path to a file that contains the list of
installed motifs.

=cut

has motifs_file	=>	(
	is			=>	'ro',
	isa			=>	'Str',
    predicate   =>  'has_motifs_file',
    writer      =>  '_set_motifs_file',
);

before  'motifs_file'   =>  sub {
    my $self = shift;
    unless ( $self->has_motifs_file ) {
        $self->_set_motifs_file($self->_get_motifs_file);
    }
};

=head2 _get_motifs_file

This private subroutine is called dynamically to return a path to the file that
contains the user's currently installed motif files.

=cut

sub _get_motifs_file    {
    my $self = shift;
    my $motifs_file =
    "$FindBin::Bin/../root/static/meme_motifs/list_of_motifs_by_gene.txt";

    # Make sure this file exists and is not empty
    ( -s $motifs_file ) ? return $motifs_file : croak "\n\nCould not get the " .
    "path to the file that defines the motifs.\n\n";
}

=head2 motif_index

This Moose attribute holds a Hash Reference containing motif names as the keys
and motif file locations as the values. These values are taken from the
motifs_file attribute.

=cut

has motif_index =>  (
    is          =>  'ro',
    isa         =>  'HashRef',
    predicate   =>  'has_motif_index',
    writer      =>  '_set_motif_index',
);

before  'motif_index'   =>  sub {
    my $self = shift;
    unless($self->has_motif_index) {
        $self->_set_motif_index($self->_define_motif_index);
    }
};

=head2 _define_motif_index

This private subroutine is run dynamically to define the list of motifs that are
available for searching within genomic sequences.

=cut

sub _define_motif_index {
	my $self = shift;

    # Pre-declare a hash reference to store motif names and file locations.
	my $motif_index = {};

	# Open the list and die if unable to read from the file
	my $motifs_list_fh = $self->motifs_file;
	open my $motifs_list_file, "<", $motifs_list_fh;
	while (<$motifs_list_file>) {
		my $motif_name = $_;
		chomp ($motif_name);

		# Define the motif file from the motif name
        my $motif_file = "$FindBin::Bin/../root/static/meme_motifs/" .
        $motif_name . '.meme';

		# Test to make sure that the file is readable
		if ( -s $motif_file ) {
			$motif_index->{$motif_name} = $motif_file;
		} else {
            croak "There was a problem reading the motif files. Please check" .
            " your installation.\n\n$motif_name\n\n";
		}
	}

	return $motif_index;
}

1;
