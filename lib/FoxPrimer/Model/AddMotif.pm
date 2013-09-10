package FoxPrimer::Model::AddMotif;
use Moose;
use Carp;
use namespace::autoclean;
use autodie;
use FindBin;
use lib "$FindBin::Bin/../lib";
use File::Which;
use IPC::Run3;
use File::Temp;
use File::Copy;
use Data::Dumper;

with 'FoxPrimer::Model::AvailableMotifs';

=head1 NAME

FoxPrimer::Model::AddMotif

=cut

=head1 AUTHOR

Jason R. Dobson, L<foxprimer@gmail.com>

=cut

=head1 DESCRIPTION

This module provides the business logic for adding a motif to the list of known
motifs for use in designing ChIP-qPCR primers.

=cut

=head2 motif_file

This Moose attribute holds the path to a user-defined motif file. This attribute
is a File::Temp object and must be defined when the class is created.

=cut

has motif_file  =>  (
    is          =>  'ro',
    isa         =>  'File::Temp',
    required    =>  1,
    lazy        =>  1,
    default     =>  sub {
        croak "\n\nYou must define the path to a motif file.\n\n";
    }
);

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

=head2 motif_name

This Moose attribute holds a string for the user-defined name of the motif they
would like to add. This attribute must be defined when creating an instance of
this class.

=cut

has motif_name  =>  (
    is          =>  'ro',
    isa         =>  'Str',
    required    =>  1,
    lazy        =>  1,
    default     =>  sub {
        croak "\n\nYou must defined a motif name.\n\n";
    }
);

=head2 add_motif

This subroutine is called to check the motif file uploaded by the user. This
subroutine returns a Boolean true if the motif is valid and has been added to
the list of available motifs and returns false if the motif was not valid.

=cut

sub add_motif   {
    my $self = shift;

    # Create a File::Temp object and write a fake sequence file
    my $fake_fasta = File::Temp->new();
    open my $fake_out, ">", $fake_fasta;
    print $fake_out join("\n",
        '>fake_seq',
        'ATGCATGCTAGATCGATGCTATGCTAGCTAGCATTCGACATGT'
    );
    close $fake_out;

    # Pre-declare an Array Ref to capture error messages produced by FIMO
    my $fimo_err = [];

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
        $fake_fasta
    );

    run3 $fimo_cmd, undef, undef, $fimo_err;

    if ( grep(/FATAL/, @{$fimo_err}) ) {
        return 0;
    } else {

        # Check to see if the motif name specified by the user is already found
        # in the user's installation
        if ( $self->motif_index->{$self->motif_name} ) {
            return 0;
        } else {

            # Define a string for the path to the location in the FoxPrimer
            # directory
            my $installation_location =
            "$FindBin::Bin/../root/static/meme_motifs/" . $self->motif_name .
            '.meme';

            # Copy the motif file contents to the installation location
            copy($self->motif_file, $installation_location) or return 0;

            # Pre-declare an Array Ref to hold the motif names
            my $motif_names_list = [];

            # Open the motif index file and add this motif name to it
            open my $index_file, "<", $self->motifs_file;
            while(<$index_file>) {
                my $index_name = $_;
                chomp($index_name);
                push(@{$motif_names_list}, $index_name);
            }
            close $index_file;
            open my $index_out, '>', $self->motifs_file;
            print $index_out join("\n", @{$motif_names_list});
            close $index_out;

            if (-s $index_out && -s $installation_location) {
                return 1;
            } else {
                croak "\n\nFailed to write motifs files to installation " . 
                "directory. Please check your installation of FoxPrimer.\n\n";
            }
        }

        return 1;
    }
}

1;
