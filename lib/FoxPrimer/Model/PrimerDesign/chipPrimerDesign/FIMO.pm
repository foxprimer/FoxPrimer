package FoxPrimer::Model::PrimerDesign::chipPrimerDesign::FIMO;
use Moose;
use Carp;
use namespace::autoclean;
use FindBin;
use lib "$FindBin::Bin/../lib";
use File::Which;
use File::Temp;
use IPC::Run3;
use autodie;

=head1 NAME

FoxPrimer::Model::PrimerDesign::chipPrimerDesign::FIMO

=head1 DESCRIPTION

This Module runs FIMO to search for the user-defined motif in the user-defined
FASTA format.

=head1 AUTHOR

Jason R Dobson L<foxprimer@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

=head2 fasta_file

This Moose object holds the File::Temp object corresponding to the location of
the FASTA file to search for motifs in.

=cut

has fasta_file  =>  (
    is          =>  'ro',
    isa         =>  'File::Temp',
    required    =>  1,
    lazy        =>  1,
    default     =>  sub {
        croak "\n\nYou must define a File::Temp object for the fasta sequence "
        . "file.\n\n";
    },
);

=head2 fasta_coordinates

This Moose attribute is dynamically defined and holds a Hash Ref of the
chromosomal coordinates that should be found in the header line of the FASTA
file in the format <chromosome>:<start>-<stop>.

=cut

has fasta_coordinates   =>  (
    is          =>  'ro',
    isa         =>  'HashRef',
    predicate   =>  'has_fasta_coordinates',
    writer      =>  '_set_fasta_coordinates',
);

before  'fasta_coordinates' =>  sub {
    my $self = shift;
    unless ( $self->has_fasta_coordinates ) {
        $self->_set_fasta_coordinates($self->_get_fasta_coordinates);
    }
};

=head2 _get_fasta_coordinates

This private subroutine is called dynamically to parse the header line of the
user-defined FASTA file to get the genomic coordinates of the sequence provided
by the twoBitToFa utility.

=cut

sub _get_fasta_coordinates  {
    my $self = shift;

    # Pre-declare a Hash Ref to hold the coordinates
    my $fasta_coordinates = {};

    # Open the FASTA file and get the header line
    open my $fasta_fh, "<", $self->fasta_file;
    my $header_line = <$fasta_fh>;
    chomp($header_line);
    if ( $header_line =~ /^>(\w+?):(\d+)-(\d+)$/ ) {
        $fasta_coordinates->{chromosome} = $1;
        $fasta_coordinates->{start} = $2;
        $fasta_coordinates->{stop} = $3;
    } else {
        croak "\n\nThere was a problem parsing the header line of the FASTA " .
        "file: " . $self->fasta_file . ".\n\n";
    }

    return $fasta_coordinates;
}

=head2 motif

This Moose object holds the user-defined pre-validated motif name to search for
in the FASTA file.

=cut

has motif   =>  (
    is          =>  'ro',
    isa         =>  'Str',
    required    =>  1,
    lazy        =>  1,
    default     =>  sub {
        croak "\n\nYou must define a motif name.\n\n";
    }
);

=head2 motif_file

This Moose attribute is dynamically defined and holds the path to the
MEME-format motif file.

=cut

has motif_file =>  (
    is          =>  'ro',
    isa         =>  'Str',
    predicate   =>  'has_motif_file',
    writer      =>  '_set_motif_file',
);

before  'motif_file'    =>  sub {
    my $self = shift;
    unless($self->has_motif_file) {
        $self->_set_motif_file($self->_get_motif_file);
    }
};

=head2 _get_motif_file

This private subroutine is dynamically defined to get the path to the motif file
based on the motif name defined by the user.

=cut

sub _get_motif_file {
    my $self = shift;
    my $motif_file = "$FindBin::Bin/../root/static/meme_motifs/" .
    $self->motif . ".meme";
    if ( -s $motif_file ) {
        return $motif_file;
    } else {
        croak "\n\nUnable to find the MEME motif file for the motif " .
        $self->motif . " defined.\n\n";
    }
}

=head2 fimo_path

This Moose attribute is dynamically defined and holds the path to the FIMO
executable.

=cut

has fimo_path    =>  (
    is          =>  'ro',
    isa         =>  'Str',
    predicate   =>  'has_fimo_path',
    writer      =>  '_set_fimo_path',
);

before  'fimo_path' =>  sub {
    my $self = shift;
    unless ($self->has_fimo_path) {
        $self->_set_fimo_path($self->_get_fimo_path);
    }
};

=head2 _get_fimo_path

This private subroutine is dynamically defined to get the path to the fimo
executable.

=cut

sub _get_fimo_path  {
    my $self = shift;
    my $fimo_path = which('fimo');
    if ( $fimo_path ) {
        return $fimo_path;
    } else {
        croak "\n\nFIMO, from the MEME suite is not found in the " .
        "\$PATH. Please check that this is installed correctly.\n\n";
    }
}

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

    # Create a File::Temp directory to hold the results of the FIMO call
    my $results_dir = File::Temp->newdir();

    # Define a string for the call for fimo to be run by IPC::Run3
    my $fimo_cmd = join(" ",
        $self->fimo_path,
        '--oc',
        $results_dir,
        '--verbosity',
        1,
        $self->motif_file,
        $self->fasta_file
    );

    # Execute the call
    run3 $fimo_cmd, undef, undef, undef;

    # Make sure a results file was produced
    unless ( -s ($results_dir . '/fimo.txt') ) {
        croak "\n\nUnable to run FIMO. Please check your installation.\n\n";
    }

    # Open the results file, iterate through and parse the results. Store the
    # coordinates in motif_coordinates
    open my $motif_results, '<', $results_dir . '/fimo.txt';
    while(<$motif_results>) {
        my $motif_results_line = $_;
        chomp($motif_results_line);

        # Skip the header line
        unless ( $motif_results_line =~ /^#/ ) {

            # Parse the line. Separate by tabs
            my @results = split(/\t/, $motif_results_line);
            
            # Calculate the true genomic positions using the relative positions
            # in the results file
            push(@{$motif_coordinates},
                {
                    chromosome  =>  $self->fasta_coordinates->{chromosome},
                    start       =>  ($self->fasta_coordinates->{start} + ($results[2]-1)),
                    stop        =>  ($self->fasta_coordinates->{start} + ($results[3]-1)),
                }
            );
        }
    }
    close $motif_results;

    return $motif_coordinates;
#    # Define a string for the FIMO directory.
#    my $fimo_dir = "$FindBin::Bin/../tmp/fimo/";
#
#    # Define a string for the FIMO file to be parsed.
#    my $fimo_fh = $fimo_dir . 'fimo.txt';
#
#    # Define a string for the FIMO call.
#    my $fimo_call = $self->fimo_executable . ' --oc ' . $fimo_dir . ' ' .
#    $self->motif_file . ' ' . $self->fasta_file;
#
#    # Execute FIMO
#    my @fimo_std_out = `$fimo_call`;
#
#    # Run the 'parse_fimo' subroutine to parse the coordinates in the FIMO
#    # results file.
#    my $parsed_fimo = $self->parse_fimo($fimo_fh);
#
#    # Add the results of 'parse_fimo' if there are any.
#    if (@$parsed_fimo) {
#        push(@$motif_coordinates, @$parsed_fimo);
#    }
#
#    # Clean up the FIMO files.
#    unlink("$FindBin::Bin/../tmp/fimo/cisml.css");
#    unlink("$FindBin::Bin/../tmp/fimo/cisml.xml");
#    unlink("$FindBin::Bin/../tmp/fimo/fimo-to-html.xsl");
#    unlink("$FindBin::Bin/../tmp/fimo/fimo.gff");
#    unlink("$FindBin::Bin/../tmp/fimo/fimo.html");
#    unlink("$FindBin::Bin/../tmp/fimo/fimo.txt");
#    unlink("$FindBin::Bin/../tmp/fimo/fimo.wig");
#    unlink("$FindBin::Bin/../tmp/fimo/fimo.xml" );
#
#    return $motif_coordinates;
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
                    chromosome  =>  $chromosome,
                    start       =>  $start,
                    end         =>  $end
                }
            );
        }
    }

    return $motif_positions;
}

__PACKAGE__->meta->make_immutable;

1;
