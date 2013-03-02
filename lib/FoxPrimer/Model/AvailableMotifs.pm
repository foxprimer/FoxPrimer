package FoxPrimer::Model::AvailableMotifs;
use Moose;
use namespace::autoclean;
use FindBin;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::AvailableMotifs - Catalyst Model

=head1 DESCRIPTION

This part of the business model dynamically returns to the user a list of
available motifs found in the 'root/static/meme_motifs/' folder.

=head1 AUTHOR

Jason R Dobson foxprimer@gmail.com

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

has motifs_file_list	=>	(
	is			=>	'ro',
	isa			=>	'Str',
	default		=>
	"$FindBin::Bin/../root/static/meme_motifs/list_of_motifs_by_gene.txt",
	required	=>	1,
);

=head2 motif_index

This subroutine creates a Hash Reference containing motif names as the keys
and motif file locations as the values.

=cut

sub motif_index {
	my $self = shift;

	# Pre-declare a hash reference to store motif names and file locations.
	my $motif_index = {};

	# Open the list and die if unable to read from the file
	my $motifs_list_fh = $self->motifs_file_list;
	open my $motifs_list_file, "<", $motifs_list_fh or die 
	"Could not open $motifs_list_fh $!";
	while (<$motifs_list_file>) {
		my $motif_name = $_;
		chomp ($motif_name);

		# Define the motif file from the motif name
		my $motif_file = 'root/static/meme_motifs/' . $motif_name . '.meme';

		# Test to make sure that the file is readable
		if ( -r $motif_file ) {
			$motif_index->{$motif_name} = $motif_file;
		} else {
			die "There was a problem reading the motif files. Please check"
			. " your installation.\n\n";
		}
	}

	return $motif_index;
}

=head2 available_motifs

This subroutine returns an Array Reference of the available motifs to the user.

=cut

sub available_motifs {
	my $self = shift;

	# Fetch the file names from the motif_index subroutine.
	my $motif_index = $self->motif_index;

	# Pre-declare an unsorted Array and a sorted Array Reference
	my (@unsorted_motifs, @sorted_motifs_temp);
	my $sorted_motifs = [];
	foreach my $motif ( keys %$motif_index ) {
		push (@unsorted_motifs, $motif);
	}

	# Sort the motifs
	@sorted_motifs_temp = sort(@unsorted_motifs);

	# Copy to an Array Ref
	$sorted_motifs = \@sorted_motifs_temp;

	return $sorted_motifs;
}


__PACKAGE__->meta->make_immutable;

1;
