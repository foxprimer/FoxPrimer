package FoxPrimer::Model::PeaksToGenes::FileStructure;
use Moose::Role;
use FindBin;
use Carp;
use File::Temp;
use autodie;
use namespace::autoclean;
use File::Which;
use IPC::Run3;

with 'FoxPrimer::Model::Primer_Database';

=head1 NAME

FoxPrimer::Model::PeaksToGenes::FileStructure

=head1 DESCRIPTION

This role provides a subroutine, which takes the genome as an argument and
returns an Array Ref of file locations for each index.

=cut

=head1 AUTHOR

Jason R Dobson, L<peakstogenes@gmail.com>

=cut

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

=head2 slop_bed_path

This Moose attribute is dynamically defined and holds the path to slopBed, which
extends BED-format coordinates.

=cut

has slop_bed_path   =>  (
    is          =>  'ro',
    isa         =>  'Str',
    predicate   =>  'has_slop_bed_path',
    writer      =>  '_set_slop_bed_path',
);

before  'slop_bed_path' =>  sub {
    my $self = shift;
    unless( $self->has_slop_bed_path ) {
        $self->_set_slop_bed_path($self->_get_slop_bed_path);
    }
};

=head2 _get_slop_bed_path

This private subroutine is called dynamically to return the path to slopBed. If
slopBed is not found, the run is killed.

=cut

sub _get_slop_bed_path  {
    my $self = shift;
    my $slop_bed_path = which('slopBed');
    if ( $slop_bed_path ) {
        return $slop_bed_path;
    } else {
        croak "\n\nslopBed was not found in the \$PATH.\n\n";
    }
}

=head2 sort_bed_path

This Moose attribute is dynamically defined and holds the path to the sortBed
utility. If sortBed cannot be found, the program will die.

=cut

has sort_bed_path   =>  (
    is          =>  'ro',
    isa         =>  'Str',
    predicate   =>  'has_sort_bed_path',
    writer      =>  '_set_sort_bed_path',
);

before  'sort_bed_path' =>  sub {
    my $self = shift;
    unless ($self->has_sort_bed_path) {
        $self->_set_sort_bed_path($self->_get_sort_bed_path);
    }
};

=head2 _get_sort_bed_path

This private subroutine is run dynamically to return the path to the sortBed
binary.

=cut

sub _get_sort_bed_path  {
    my $self = shift;
    my $sort_bed_path = which('sortBed');
    if ( $sort_bed_path ) {
        return $sort_bed_path;
    } else {
        croak "\n\nCould not find sortBed in the \$PATH.\n\n";
    }
}

=head2 get_index

This subroutine is passed a genome string and a Hash Ref of chromosome sizes as
arguments and returns an Array Ref of BED-format index files that will be used
to determine the relative locations of created primer pairs.

=cut

sub get_index {
    my $self = shift;
    my $genome = shift;
    my $chrom_sizes_hash = shift;

    # Determine if there is an index file for the user-defined genome
    my $index_fh =
    "$FindBin::Bin/../root/static/files/peakstogenes_index_files/$genome";

    # If the file exists, return it, otherwise run the _create_index_file
    # subroutine to create the index file and then return it.
    if ( -s $index_fh ) {
        return $index_fh;
    } else {
        return $self->_create_index_file($genome, $chrom_sizes_hash);
    }

#	my ($self, $genome) = @_;
#	if ( $genome eq 'hg19' ) {
#		return $self->_can_open_files($human_index);
#	} elsif ( $genome eq 'mm9' ) {
#		return $self->_can_open_files($mouse_index);
#	} elsif ( $genome eq 'dm3' ) {
#		return $self->_can_open_files($dmelanogaster_index);
#	} else {
#		die "\n\nThere was a problem in the get_index subroutine returning the proper index of genomic locations.\n\n";
#	}
}

=head2 _create_index_file

This subroutine is called to create an index file for the current user-defined
genome if the file does not already exist in the user's current installation of
FoxPrimer. This subroutine is passed two argument: a string for the genome and a
Hash Ref of chromosome sizes for the current genome.

=cut

sub _create_index_file  {
    my $self = shift;
    my $genome_string = shift;
    my $chr_sizes = shift;

    # Run the _write_chromosome_sizes subroutine to get a File::Temp object for
    # the chromosome sizes file
    my $chr_sizes_file = $self->_write_chromosome_sizes($chr_sizes);

    # Run the _get_genomic_coordinates subroutine to return a File::Temp object
    # of unsorted genomic coordinates in BED-format.
    my $unsorted_genomic_coordinates_fh =
    $self->_get_genomic_coordinates($genome_string);

    # Run the _extend_and_sort_genomic_coordinates subroutine to get a string
    # for the path to the extended and sorted BED-format coordinates of all
    # RefSeq transcripts for the user-defined genome that is within the
    # FoxPrimer directory.
    my $index_fh = $self->_extend_and_sort_genomic_coordinates(
        $unsorted_genomic_coordinates_fh,
        $chr_sizes_file,
        $genome_string,
    );

    return $index_fh;
}

=head2 _write_chromosome_sizes

This subroutine takes a Hash Ref of chromosome sizes as an argument, writes
these coordinates to file in tab-delimited format and returns a File::Temp
object of the chromosome sizes.

=cut

sub _write_chromosome_sizes {
    my $self = shift;
    my $chr_sizes = shift;

    # Convert the chromosome sizes Hash Ref into an Array Ref
    my $chr_sizes_array = [];
    foreach my $chr ( keys %{$chr_sizes} ) {
        push(@{$chr_sizes_array}, join("\t", $chr, $chr_sizes->{$chr}));
    }

    # Create a new File::Temp object and write the chromosome sizes to file
    my $chr_sizes_fh = File::Temp->new();
    open my $chr_sizes_file, ">", $chr_sizes_fh;
    print $chr_sizes_file join("\n", @{$chr_sizes_array});
    close $chr_sizes_file;

    return $chr_sizes_fh;
}

=head2 _get_genomic_coordinates

This private subroutine is passed a genome string and interacts with the UCSC
MySQL server to return a File::Temp object of BED-format coordinates for each
RefSeq transcript. Each transcript will be in the fourth column of the BED file
with the gene symbol prepended to the RefSeq accession (separated by a '-'
symbol).

=cut

sub _get_genomic_coordinates    {
    my $self = shift;
    my $genome_string = shift;
    
    # Interact with the UCSC MySQL server to get the genomic coordinates for the
    # RefSeq genes in the user-defined genome
    my $ucsc_schema = $self->define_ucsc_schema($genome_string);

    # Define the columns to fetch from the UCSC refGene table
    my $columns = join(", ",
		"chrom",
		"txStart",
		"txEnd",
		"cdsStart",
		"cdsEnd",
		"exonCount",
		"exonStarts",
		"exonEnds",
		"name",
        "name2",
		"strand",
    );

    # Extract all of the RefSeq gene coordinates
	my $refseq = $ucsc_schema->storage->dbh_do(
		sub {
			my ($storage, $dbh, @args) = @_;
			$dbh->selectall_hashref("SELECT $columns FROM refGene",
				["name"]);
		},
	);

    unless ( scalar ( keys %{$refseq} ) >= 1 ) {
        croak "\n\nUnable to fetch RefSeq coordinates for $genome_string " .
        "from the UCSC MySQL server.\n\n";
    }

    # Pre-declare an Array Ref to hold the coordinates in BED-format.
    my $coordinates = [];

    # Add the coordinates in the refseq Hash Ref to the coordinates Array Ref in
    # BED-format. The fourth column will identify the gene.
    foreach my $refseq_accession ( keys %{$refseq} ) {
        push(@{$coordinates},
            join("\t",
                $refseq->{$refseq_accession}{chrom},
                $refseq->{$refseq_accession}{cdsStart},
                $refseq->{$refseq_accession}{cdsEnd},
                $refseq->{$refseq_accession}{name2} . '-' .
                $refseq->{$refseq_accession}{name},
                $refseq->{$refseq_accession}{strand}
            )
        );
    }

    # Create a File::Temp object to write the unextended coordinates to file.
    my $unextended_coordinates = File::Temp->new();

    # Write the unextended_coordinates to file
    open my $unextended_out, ">", $unextended_coordinates;
    print $unextended_out join("\n", @{$coordinates});
    close $unextended_out;

    if ( -s $unextended_coordinates ) {
        return $unextended_coordinates;
    } else {
        croak "\n\nUnable to create a genomic index file for $genome_string.\n\n";
    }
}

=head2 _extend_and_sort_genomic_coordinates

This private subroutine is passed the File::Temp object that contains the raw
genomic coordinates, the File::Temp object for the chromosome sizes and the
genome string. This subroutine then makes calls to slopBed and sortBed to return
the path to a file in the FoxPrimer directory for the user-defined genome.

=cut

sub _extend_and_sort_genomic_coordinates    {
    my $self = shift;
    my $raw_coordinates_fh = shift;
    my $chromosome_sizes_fh = shift;
    my $genome_string = shift;

    # Define a path for the genome coordinates
    my $genomic_coordinates_fh =
    "$FindBin::Bin/../root/static/files/peakstogenes_index_files/$genome_string";

    # Create a File::Temp object to write the extended coordinates
    my $extended_coordinates = File::Temp->new();

    # Create a slopBed command to run for extending genomic coordinates
    my $slop_bed_cmd = join(" ",
        $self->slop_bed_path,
        '-pct',
        '-l',
        0.2,
        '-r',
        0.2,
        '-i',
        $raw_coordinates_fh,
        '-g',
        $chromosome_sizes_fh,
        '>',
        $extended_coordinates
    );

    # Run the slopBed command with run3
    run3 $slop_bed_cmd, undef, undef, undef;

    # Make sure that the command execution worked
    unless ( -s $extended_coordinates ) {
        croak "\n\nUnable to extend the coordinates.\n\n";
    }

    # Create a command to sort the extended coordinates. Write the results to
    # the genomic_coordinates_fh
    my $sort_bed_cmd = join(" ",
        $self->sort_bed_path,
        '-i',
        $extended_coordinates,
        '>',
        $genomic_coordinates_fh
    );

    # Execute the sortBed command
    run3 $sort_bed_cmd, undef, undef, undef;

    # Make sure the coordinates were written
    if ( -s $genomic_coordinates_fh ) {
        return $genomic_coordinates_fh;
    } else {
        croak "\n\nUnable to create a genomic index file for " .
        "$genome_string.\n\n";
    }
}

1;
