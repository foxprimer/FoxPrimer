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

=head2 _fimo_executable

This Moose object holds the path to the FIMO executable.

=cut

has _fimo_executable	=>	(
	is			=>	'ro',
	isa			=>	'Str',
	required	=>	1,
	lazy		=>	1,
	default		=>	sub {
		my $self = shift;
		my $fimo_path = which('fimo');
		if ( $fimo_path ) {
			return $fimo_path;
		} else {
			die "FIMO, from the MEME suite is not found in the " .
			"\$PATH. Please check that this is installed correctly.";
		}
	},
	reader		=>	'fimo_executable'
);

=head2 find_motifs

This subroutine makes a call to FIMO and search for the user-defined motif
in the user-defined FASTA sequence file. This subroutine will parse the
FIMO results, and return an Array Ref of Hash Refs for coordinates.

=cut

sub find_motifs {
	my $self = shift;

	# Pre-declare an Array Ref to hold the coordinates of the found motifs
	# matches.
	my $motif_coordinates = [];

	# Define a string for the FIMO directory.
	my $fimo_dir = "$FindBin::Bin/../tmp/fimo/";

	# Define a string for the FIMO file to be parsed.
	my $fimo_fh = $fimo_dir . 'fimo.txt';

	# Define a string for the FIMO call.
	my $fimo_call = $self->fimo_executable . ' --oc ' . $fimo_dir . ' ' .
	$self->motif_file . ' ' . $self->fasta_file;

	# Execute FIMO
	my @fimo_std_out = `$fimo_call`;

	# Run the 'parse_fimo' subroutine to parse the coordinates in the FIMO
	# results file.
	my $parsed_fimo = $self->parse_fimo($fimo_fh);

	# Add the results of 'parse_fimo' if there are any.
	if (@$parsed_fimo) {
		push(@$motif_coordinates, @$parsed_fimo);
	}

	# Clean up the FIMO files.
	unlink("$FindBin::Bin/../tmp/fimo/cisml.css");
	unlink("$FindBin::Bin/../tmp/fimo/cisml.xml");
	unlink("$FindBin::Bin/../tmp/fimo/fimo-to-html.xsl");
	unlink("$FindBin::Bin/../tmp/fimo/fimo.gff");
	unlink("$FindBin::Bin/../tmp/fimo/fimo.html");
	unlink("$FindBin::Bin/../tmp/fimo/fimo.txt");
	unlink("$FindBin::Bin/../tmp/fimo/fimo.wig");
	unlink("$FindBin::Bin/../tmp/fimo/fimo.xml" );

	return $motif_coordinates;
}

=head2 parse_fimo

This subroutine takes the path to the FIMO results file as an argument, and
parses the results in the file into coordinates returned as an Array Ref of
Hash Refs.

=cut

sub parse_fimo {
	my ($self, $fimo_fh) = @_;

	# Pre-declare an Array Ref to hold to motif positions.
	my $motif_positions = [];

	# Open the FIMO results file, and iterate through the lines
	open my $fimo_file, "<", $fimo_fh or die "Could not read from " .
	$fimo_fh . " $!\n";
	while(<$fimo_file>) {
		my $line = $_;
		chomp($line);
		
		# Skip the header line, which is preceded by a '#' character.
		unless ($line =~ /^#/) {

			# Split the line by the Tab character.
			my ($motif_name, $chromosome, $start, $end, $rest_of_line) =
			split(/\t/, $line);

			# Convert the locations if FIMO find the match on the negative
			# strand.
			if ( $start > $end ) {
				my $temp_loc = $start;
				$start = $end;
				$end = $temp_loc;
			}

			# Add the coordinates as a Hash Ref to the motif_positions
			# Array Ref.
			push(@$motif_positions,
				{
					chromosome	=>	$chromosome,
					start		=>	$start,
					end			=>	$end
				}
			);
		}
	}

	return $motif_positions;
}

__PACKAGE__->meta->make_immutable;

1;
