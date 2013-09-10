package FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankRetriever;
use Moose::Role;
use Carp;
use File::Fetch;
use File::Temp;
use File::Basename;
use autodie;
use namespace::autoclean;

use Data::Dumper;

=head1 NAME

FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankRetriever

=head1 DESCRIPTION

This Moose::Role exports the methods to interact with NCBI to fetch sequence
objects for the cDNA and corresponding genomic DNA sequences.

=head1 AUTHOR

Jason R Dobson L<foxprimer@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

=head2 ncbi_soap_base

This Moose attribute holds a URL string that corresponds to the base arguments
that will be supplied for all SOAP requests to NCBI. This value is defined at
when the object is created.

=cut

has ncbi_soap_base  =>  (
    is          =>  'ro',
    isa         =>  'Str',
    writer      =>  '_set_ncbi_soap_base',
    default     =>
    'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&rettype=fasta&retmode=text',
);

=head2 get_objects

This subroutine interacts with NCBI to fetch the sequence objects for both the
cDNA and genomic DNA. Both objects are returned by the
FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankRetriever::get_objects
subroutine. Also, this subroutine also returns the description of the mRNA
in scalar string format.

This subroutine is passed the following arguments:

    1. cDNA GI
    2. gDNA GI
    3. gDNA Start
    4. gDNA Stop
    5. gDNA Strand

And returns a File::Temp object for the cDNA, a File::Temp object for the gDNA
and a string corresponding to the mRNA description.

=cut

sub get_objects {
	my $self = shift;
    my $cdna_gi = shift;
    my $gdna_gi = shift;
    my $gdna_start = shift;
    my $gdna_stop = shift;
    my $gdna_strand = shift;

    # Get the cDNA sequence object, cDNA sequence, and the mRNA description by
    # running the get_cdna_object subroutine
    my ($cdna_sequence_object, $cdna_seq, $mrna_description) =
    $self->get_cdna_object($cdna_gi);

	# Get the genomic DNA sequence object by running the get_genomic_dna_object
    # subroutine
	my $genomic_dna_sequence_object = $self->get_genomic_dna_object(
        $gdna_gi, $gdna_start, $gdna_stop, $gdna_strand
    );

	# Return the sequence objects, the mRNA description, and the cDNA sequence
    # string
	return ($cdna_sequence_object, $genomic_dna_sequence_object,
		$mrna_description, $cdna_seq
	);
}

=head2 get_cdna_object

This subroutine is used for the retrieval of the cDNA sequence object from
NCBI. It is passed an integer value that corresponds to the cDNA to be fetched.
This subroutine returns a File::Temp object that corresponds to the location of
the temporary cDNA sequence file, a string of the cDNA sequence, and a string of
the mRNA description.

=cut

sub get_cdna_object {
	my $self = shift;
    my $gi = shift;

    # Create a new File::Temp object
    my $cdna_file = File::Temp->new(
        SUFFIX  =>  '.fa',
    );

    # Get the path to the temporary file
    my ($cdna_filname, $cdna_dir, $suffix) = fileparse($cdna_file);

    # Define a string to interact with the NCBI SOAP utility with File::Fetch
    my $cdna_string = join('', $self->ncbi_soap_base, '&id=', $gi);
    my $cdna_fetch = File::Fetch->new(
        uri     =>  $cdna_string,
    );
    my $cdna_file_location = $cdna_fetch->fetch(
        to  =>  "$cdna_dir"
    ) or croak "\n\nCould not fetch file from NCBI SOAP for cDNA gi: $gi.\n\n";

    # Pre-declare a string to hold the mRNA description
    my $mrna_description = '';

    # Pre-declare a string to hold the cDNA sequence
    my $cdna_sequence = '';

    # Print the contents of the temporary File::Fetch object to the File::Temp
    # file. Take the header line and parse out the mRNA description, add the
    # rest of the lines to the cDNA sequence string.
    open my $cdna_file_handle, '<', $cdna_file_location;
    open my $temp_cdna_file, '>>', $cdna_file;
    while(<$cdna_file_handle>) {
        my $line = $_;
        print $temp_cdna_file $line;
        chomp($line);
        if ( $line =~ /^>/ ) {
            my @header_items = split(/\|/, $line);
            $mrna_description = $header_items[-1];
        } else {
            if ( $line ) {
                if ( $cdna_sequence ) {
                    $cdna_sequence .= $line;
                } else {
                    $cdna_sequence = $line;
                }
            }
        }
    }
    close $cdna_file_handle;
    close $temp_cdna_file;

    # Make sure the temporary File::Fetch file is removed
    unlink($cdna_file_location);

    return ($cdna_file, $cdna_sequence, $mrna_description);
}

=head2 get_genomic_dna_object

This subroutine is used for the retrieval of the genomic DNA object from
NCBI. This subroutine is passed the following values:

    1. gDNA GI
    2. gDNA subsequence start
    3. gDNA subsequence stop
    4. gDNA strand on which the gene is encoded

and returns a File::Temp object for the gDNA file in FASTA format.

=cut

sub get_genomic_dna_object {
	my $self = shift;
    my $gi = shift;
    my $start = shift;
    my $stop = shift;
    my $orientation = shift;

    # Based on which strand of the genomic DNA the mRNA is found, determine
    # which number will be used for Bio::DB::GenBank (1 for positive strand and
    # 2 for negative strand).
	my $strand = '';
	if ( $orientation eq '+') {
		$strand = 1;
	} elsif ( $orientation eq '-' ) {
		$strand = 2;
	} else {
        croak "\n\nThe orientation of the mRNA was not properly designated as" .
        " either '+' or '-'\n\n";
	}

    # Create a new File::Temp object
    my $gdna_file = File::Temp->new(
        SUFFIX  =>  '.fa',
    );

    # Get the path to the temporary file
    my ($gdna_filname, $gdna_dir, $suffix) = fileparse($gdna_file);

    # Define a string to interact with the NCBI SOAP utility with File::Fetch
    my $gdna_string = join('', 
        $self->ncbi_soap_base, 
        '&id=', $gi,
        '&seq_start=', $start,
        '&seq_stop=', $stop,
        '&strand=', $strand,
    );
    my $gdna_fetch = File::Fetch->new(
        uri     =>  $gdna_string,
    );
    my $gdna_file_location = $gdna_fetch->fetch(
        to  =>  "$gdna_dir"
    ) or croak "\n\nCould not fetch file from NCBI SOAP for gDNA gi: $gi.\n\n";

    # Print the contents of the temporary File::Fetch object to the File::Temp
    # file. Take the header line and parse out the mRNA description, add the
    # rest of the lines to the gDNA sequence string.
    open my $gdna_file_handle, '<', $gdna_file_location;
    open my $temp_gdna_file, '>>', $gdna_file;
    while(<$gdna_file_handle>) {
        my $line = $_;
        print $temp_gdna_file $line;
    }
    close $gdna_file_handle;
    close $temp_gdna_file;

    # Make sure the temporary File::Fetch file is removed
    unlink($gdna_file_location);

    return $gdna_file;
}

1;
