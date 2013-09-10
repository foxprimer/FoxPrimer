package FoxPrimer::Model::PrimerDesign::MisprimingLibrary;
use Moose::Role;
use namespace::autoclean;
use FindBin;
use lib "$FindBin::Bin/../lib";

=head1 NAME

FoxPrimer::Model::PrimerDesign::MisprimingLibrary

=cut

=head1 AUTHOR

Jason R. Dobson, L<foxprimer@gmail.com>

=cut

=head1 DESCRIPTION

This Moose role exports the functions to link mispriming files for primer3.

=cut

=head2 mispriming_files

This Moose attribute holds a Hash Ref of commonly used mispriming library names
as keys and the path to the corresponding file as the values.

=cut

has mispriming_files    =>  (
    is          =>  'ro',
    isa         =>  'HashRef',
    predicate   =>  'has_mispriming_files',
    writer      =>  '_set_mispriming_files',
);

before  'mispriming_files'  =>  sub {
    my $self = shift;
    unless($self->has_mispriming_files) {
        $self->_set_mispriming_files($self->_get_mispriming_files);
    }
};

=head2 _get_mispriming_files

This private subroutine is called dynamically to return a Hash Ref of mispriming
files. If the user has removed a mispriming file from the required location it
will not be included in the Hash Ref returned.

=cut

sub _get_mispriming_files   {
    my $self = shift;

    # Pre-declare a Hash Ref to hold the names and files
    my $mispriming_files = {};

    # Add the files if they exist
    $mispriming_files->{HUMAN} =
    "$FindBin::Bin/../root/static/files/primer3_mispriming_libs/HUMAN" 
    if ( -s "$FindBin::Bin/../root/static/files/primer3_mispriming_libs/HUMAN");

    $mispriming_files->{RODENT_AND_SIMPLE} =
    "$FindBin::Bin/../root/static/files/primer3_mispriming_libs/RODENT_AND_SIMPLE" 
    if ( -s "$FindBin::Bin/../root/static/files/primer3_mispriming_libs/RODENT_AND_SIMPLE");

    $mispriming_files->{RODENT} =
    "$FindBin::Bin/../root/static/files/primer3_mispriming_libs/RODENT" 
    if ( -s "$FindBin::Bin/../root/static/files/primer3_mispriming_libs/RODENT");

    $mispriming_files->{DROSOPHILA} =
    "$FindBin::Bin/../root/static/files/primer3_mispriming_libs/DROSOPHILA_FIXED" 
    if ( -s "$FindBin::Bin/../root/static/files/primer3_mispriming_libs/DROSOPHILA_FIXED");

    return $mispriming_files;
}

1;
