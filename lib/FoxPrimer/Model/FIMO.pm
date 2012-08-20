package FoxPrimer::Model::FIMO;
use Moose;
use namespace::autoclean;
use FoxPrimer::Model::ChIP_Primer_Design;
use FoxPrimer::Model::ChIP_Primer_Design::TwoBitToFa;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::FIMO - Catalyst Model

=head1 DESCRIPTION

This module uses FIMO from the MEME suite to determine whether a user-defined
genomic DNA motif exists and then determine the position at which that motif
is found within the interval.

=head1 AUTHOR

Jason R Dobson,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 Moose declarations

This section contains the Moose declarations and requirements for this module.

=cut

has fimo_executable	=>	(
	is			=>	'ro',
	isa			=>	'Str',
	default		=>	sub {
		my $self = shift;
		my $fimo_path = `which fimo`;
		chomp ($fimo_path);
		return $fimo_path;
	},
	required	=>	1,
);

has chromosome	=>	(
	is			=>	'rw',
	isa			=>	'Str',
);

has start		=>	(
	is			=>	'rw',
	isa			=>	'Int',
);

has stop	=>	(
	is			=>	'rw',
	isa			=>	'Int',
);

has motif_name	=>	(
	is			=>	'rw',
	isa			=>	'Str',
);

has genome	=>	(
	is			=>	'rw',
	isa			=>	'Str',
);

has product_size	=>	(
	is			=>	'rw',
	isa			=>	'Str',
);

has peak_name	=>	(
	is			=>	'rw',
	isa			=>	'Str',
);

=head2 run

This is the main subroutine called by the Catalyst Controller. It returns
either the positions of the motifs within each interval, or if there aren't
any motifs found, it will return a boolean false.

=cut

sub run {
	my $self = shift;
	# Create the temp fasta file.
	my $twoBitToFa = FoxPrimer::Model::ChIP_Primer_Design::TwoBitToFa->new(
		chromosome	=>	$self->chromosome,
		start		=>	$self->start,
		stop		=>	$self->stop,
		genome		=>	$self->genome,
	);
	$twoBitToFa->create_temp_fasta;
	# Call FIMO
	my $fimo_executable = $self->fimo_executable;
	my $fimo_out_dir = 'tmp/fimo/';
	my $motif = 'root/static/meme_motifs/' . $self->motif_name . '.meme';
	my $fasta = 'tmp/fasta/temp.fa';
	`$fimo_executable --oc $fimo_out_dir $motif $fasta`;
	my $motif_positions = $self->_parse_fimo;
	# Clean up the tmp directories
	`rm tmp/fasta/temp.fa`;
	`rm tmp/fimo/cisml.css`;
	`rm tmp/fimo/cisml.xml`;
	`rm tmp/fimo/fimo-to-html.xsl`;
	`rm tmp/fimo/fimo.gff`;
	`rm tmp/fimo/fimo.html`;
	`rm tmp/fimo/fimo.txt`;
	`rm tmp/fimo/fimo.wig`;
	`rm tmp/fimo/fimo.xml`;
	return $motif_positions;
}

=head _parse_fimo

This is a private subroutine which parses the results of the FIMO call.
Two results are returned, one is an Array Reference of tab-delimited
coordinates, the other result is Boolean value indicating whether any
motifs were discovered.

=cut

sub _parse_fimo {
	my $self = shift;
	# The location of the FIMO out is always the same
	my $fimo_fh = 'tmp/fimo/fimo.txt';
	# Predeclare the Array Reference where discovered motifs will be stored
	my $motif_positions = [];
	# Predeclare the Boolean variable which designates whether motifs were
	# found or not
	open my $fimo_file, "<", $fimo_fh or die "Could not read from $fimo_fh $!\n";
	my @fimo_lines = <$fimo_file>;
	close $fimo_file;
	if ( @fimo_lines > 1 ) {
		# Iterate through the lines of the FIMO outfile
		# The first line is a header, and it is skipped
		for ( my $i = 1; $i < @fimo_lines; $i++ ) {
			my ($pattern_name, $chromosome, $start, $stop, $rest_of_line) = split(/\t/, $fimo_lines[$i]);
			# Determine if the motif was matched on the forward or reverse strand
			my ($higher, $lower);
			if ( $stop > $start ) {
				$higher = $stop;
				$lower = $start;
			} elsif ( $start > $stop ) {
				$higher = $start;
				$lower = $stop;
			}
			# Use the extend_coordinates subroutine from the Model ChIP_Primer_Design
			# to safely extend the coordinates of each discovered motif
			my $extend_coordinates = FoxPrimer::Model::ChIP_Primer_Design->new(
				genome	=>	$self->genome,
			);
			my ($min_product_size, $max_product_size) = split(/-/, $self->product_size);
			my ($extended_start, $extended_stop, $relative_coordinates_string) = $extend_coordinates->extend_coordinates($chromosome, $lower, $higher, $max_product_size);
			# Push the coordinates at the $motif_positions Array Reference
			push(@$motif_positions,
				{
					chromosome					=>	$chromosome,
					genomic_dna_start			=>	$extended_start,
					genomic_dna_stop			=>	$extended_stop,
					interval_start				=>	$self->start,
					interval_stop				=>	$self->stop,
					motif_start					=>	$lower,
					motif_stop					=>	$higher,
					motif_name					=>	$self->motif_name,
					relative_coordinates_string	=>	$relative_coordinates_string,
					peak_name					=>	$self->peak_name,
				}
			);
		}
	}
	return $motif_positions;
}

__PACKAGE__->meta->make_immutable;

1;
