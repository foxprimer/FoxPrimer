package FoxPrimer::Model::PrimerDesign::chipPrimerDesign::twoBitToFa;
use Moose;
use Carp;
use namespace::autoclean;
use FindBin;
use lib "$FindBin::Bin/../lib";
use File::Which;
use File::Temp;
use File::Fetch;
use IPC::Run3;
use Data::Dumper;

=head1 NAME

FoxPrimer::Model::PrimerDesign::chipPrimerDesign::twoBitToFa

=head1 DESCRIPTION

This module takes writes the FASTA-format sequence of the user-defined
coordinates to a temporary file.

=head1 AUTHOR

Jason R Dobson L<foxprimer@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

=head2 genome

This Moose attribute holds the string for the user-defined genome. This object
must be defined when this class is used.

=cut

has genome  =>  (
    is          =>  'ro',
    isa         =>  'Str',
    required    =>  1,
    lazy        =>  1,
    default     =>  sub {
        croak "\n\nYou must define a genome.\n\n";
    },
);

=head2 coordinates

This Moose attribute holds an Array Ref of coordinates in Hash Ref format. This
attribute must be defined at object creation.

=cut

has coordinates =>  (
    is          =>  'ro',
    isa         =>  'ArrayRef',
    required    =>  1,
    lazy        =>  1,
    default     =>  sub {
        croak "\n\nYou must define an Array Ref of BED-format coordinates.\n\n";
    },
);

=head2 twobit_path

This Moose attribute contains the path to the Kent utility twoBitToFa. This
attribute is dynamically defined and must be a valid path.

=cut

has twobit_path  =>  (
    is          =>  'ro',
    isa         =>  'Str',
    predicate   =>  'has_twobit_path',
    writer      =>  '_set_twobit_path',
);

before  'twobit_path'   =>  sub {
    my $self = shift;
    unless ( $self->has_twobit_path ) {
        $self->_set_twobit_path($self->_get_twobit_path);
    }
};

=head2 _get_twobit_path

This private subroutine is dynamically run to get the path to the twoBitToFa
executable.

=cut

sub _get_twobit_path    {
    my $self = shift;

    # Get the twoBitToFa path
    my $twobit_path = which('twoBitToFa');
    chomp($twobit_path);
    $twobit_path ? return $twobit_path : croak
    "\n\nThe \$PATH to twoBitToFa was not found.\n\n";
}

=head2 twobit_file

This Moose attribute is dynamically defined based on the user-defined genome and
holds the path to the 2bit file for the user-defined genome. If the particular
genome can not be found, this attribute will cause the required 2bit file to be
downloaded from UCSC if the user has entered a valid genome.

=cut

has twobit_file =>  (
    is          =>  'ro',
    isa         =>  'Str',
    predicate   =>  'has_twobit_file',
    writer      =>  '_set_twobit_file',
);

before  'twobit_file'   =>  sub {
    my $self = shift;
    unless ( $self->has_twobit_file ) {
        $self->_set_twobit_file($self->_get_twobit_file);
    }
};

=head2 _get_twobit_file

This private subroutine is called dynamically to return a string corresponding
to the path to a 2bit-format file for the user-defined genome. This subroutine
will download a new file from UCSC if one is not found in the
root/static/files/twobit_genomes directory.

=cut

sub _get_twobit_file    {
    my $self = shift;

    # Define a path to the 2bit file based on the user-defined genome
    my $twobit_fh = "$FindBin::Bin/../root/static/files/twobit_genomes/" .
    $self->genome . "/" . $self->genome . ".2bit";

    # Test to determine whether the file exists and is non-zero. If it does,
    # return that path. If not, fetch the file from UCSC and then return the
    # path.
    if ( -s $twobit_fh ) {
        return $twobit_fh;
    } else {

        # Create a File::Fetch object
        #
        # Define the URL path to the 2bit file from UCSC
        my $remote_url = "http://hgdownload.cse.ucsc.edu/gbdb/" . $self->genome
        . "/" . $self->genome . ".2bit";
        my $fetch = File::Fetch->new(
            uri =>  $remote_url
        );

        my $fetched_twobit = $fetch->fetch(
            to  =>  "$FindBin::Bin/../root/static/files/twobit_genomes"
        );

        # Make sure the file was downloaded and is non-zero
        if ( -s $fetched_twobit ) {
            return $fetched_twobit;
        } else {
            croak "\n\nThere was a problem downloading the 2bit file for the " .
            "genome: " . $self->genome . ".\n\n";
        }
    }
}

=head2 create_temp_fasta

This subroutine takes the user-defined coordinates and writes the sequence at
these coordinates to a temporary file in FASTA format using twoBitToFa.  An
Array Ref of File::Temp objects corresponding to the temporary FASTA-format
files is returned.

=cut

sub create_temp_fasta {
    my $self = shift;

    # Pre-declare an Array Ref to hold the File::Temp objects
    my $fasta_files = [];

    # Iterate through the coordinates
    foreach my $coordinates ( @{$self->coordinates} ) {

        # Copy the coordinates to local variables
        my $chr = $coordinates->{chromosome};
        my $start = $coordinates->{start};
        my $stop = $coordinates->{stop};

        # Create a new File::Temp object
        my $temp_fasta = File::Temp->new(
            SUFFIX  =>  '.fa',
        );

        # Define a string for the twoBitToFa command
        my $twobit_cmd = join(" ",
            $self->twobit_path,
            $self->twobit_file . ":$chr:$start-$stop",
            $temp_fasta,
            '-noMask',
        ); 

        # Run the command with IPC::Run3
        run3 $twobit_cmd, undef, undef, undef;

        # Make sure that something was written to file. If so add it to
        # fasta_files
        if ( -s $temp_fasta ) {
            push(@{$fasta_files}, $temp_fasta);
        } else {
            croak "\n\nUnable to write coordinates for $self->genome " .
            "$chr:$start-$stop.\n\n";
        }
    }

    return $fasta_files;
}

__PACKAGE__->meta->make_immutable;

1;
