use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Data::Dumper;
use File::Temp;
use autodie;


BEGIN { 
    
    # Make sure the required modules can be used.
    use_ok  'FoxPrimer::Model::PrimerDesign::chipPrimerDesign';
    use_ok  'FoxPrimer::Model::PrimerDesign::chipPrimerDesign::twoBitToFa';
    use_ok  'FoxPrimer::Model::PrimerDesign::chipPrimerDesign::FIMO';
    use_ok  'FoxPrimer::Model::PeaksToGenes';

    # Create a File::Temp file handle. Print BED-format coordinates to file.
    my $bed_fh = File::Temp->new();
    open my $bed_file, ">", $bed_fh;
    print $bed_file join("\n",
        join("\t", 'chr4', 64443, 64444),
        join("\t", 'chr4', 77091, 77092),
        join("\t", 'chr4', 79769, 79770),
        join("\t", 'chr4', 80735, 80736),
        join("\t", 'chr4', 81374, 81375),
        join("\t", 'chr4', 84148, 84149),
        join("\t", 'chr4', 87923, 87924),
        join("\t", 'chr4', 89416, 89417),
        join("\t", 'chr4', 90337, 90338),
        join("\t", 'chr4', 110532, 110533),
    );
    close $bed_file;

    # Create an instance of FoxPrimer::Model::PrimerDesign::chipPrimerDesign and
    # make sure it was created properly.
    my $primer_design = FoxPrimer::Model::PrimerDesign::chipPrimerDesign->new(
        product_size    =>  '70-150',
        motif           =>  'Cebpa',
        genome          =>  'dm3',
        bed_file        =>  $bed_fh,
        mispriming_file =>
        "$FindBin::Bin/../root/static/files/primer3_mispriming_libs/DROSOPHILA_FIXED",
    );
    isa_ok($primer_design, 'FoxPrimer::Model::PrimerDesign::chipPrimerDesign');

    # Make sure the object can execute the ucsc_schema function, which is a
    # Moose attribute that holds a FoxPrimer::Model::UCSC object that creates a
    # DBIx Schema to connect to the UCSC MySQL server.
    can_ok($primer_design, 'ucsc_schema');
    my $ucsc_schema = $primer_design->ucsc_schema;
    isa_ok($ucsc_schema, 'FoxPrimer::Model::UCSC');

    # Make sure the object can execute the 'chromosome_sizes' function, which is
    # a Moose attribute that hold a Hash Ref of chromosome sizes for the
    # user-defined genome (in this test script: dm3).
    can_ok($primer_design, 'chromosome_sizes');
    my $chromosome_sizes = $primer_design->chromosome_sizes;
    isa_ok($chromosome_sizes, 'HASH');
    cmp_ok($chromosome_sizes->{chrX}, '==', 22422827,
        'Chromosome X is 22422827bp long.'
    );
    cmp_ok($chromosome_sizes->{chr4}, '==', 1351857,
        'Chromosome 4 is 1351857bp long.'
    );

    # Make sure the mispriming file is readable
    can_ok($primer_design, 'mispriming_file');
    ok(-s $primer_design->mispriming_file, 'Mispriming file is readable');

    # Make sure the _check_bed_file subroutine can be run and returns the
    # correct values
    can_ok($primer_design, '_check_bed_file');
    my ($bed_coordinates, $bed_file_errors) = $primer_design->_check_bed_file;
    isa_ok($bed_coordinates, 'ARRAY');
    isa_ok($bed_file_errors, 'ARRAY');
    ok( scalar @{$bed_file_errors} == 0,
        'The are no errors in the BED file.'
    );
    ok( scalar @{$bed_coordinates} == 10,
        'The correct number of BED-format coordinates were returned'
    );
    isa_ok($bed_coordinates->[0], 'HASH');
    cmp_ok($bed_coordinates->[5]{chromosome}, 'eq', 'chr4',
        'The chromosome field equals chr4'
    );
    cmp_ok($bed_coordinates->[5]{start}, '==', 84148,
        'The start field equals 84148'
    );
    cmp_ok($bed_coordinates->[5]{stop}, '==', 84149,
        'The stop field equals 84149'
    );

    # Test the '_get_extended_bed_coordinates' subroutine and make sure the
    # correct values are returned
    can_ok($primer_design, '_get_extended_bed_coordinates');
    my $extended_bed_coordinates = $primer_design->_get_extended_bed_coordinates;
    isa_ok($extended_bed_coordinates, 'ARRAY');
    isa_ok($extended_bed_coordinates->[0], 'HASH');
    cmp_ok($extended_bed_coordinates->[5]{chromosome}, 'eq', 'chr4',
        'The chromosome field equals chr4'
    );
    cmp_ok($extended_bed_coordinates->[5]{target_start}, '==', 84148,
        'The target start field equals 84148'
    );
    cmp_ok($extended_bed_coordinates->[5]{target_stop}, '==', 84149,
        'The target stop field equals 84149'
    );
    cmp_ok($extended_bed_coordinates->[5]{start}, '==', 83849,
        'The extended start field equals 83849'
    );
    cmp_ok($extended_bed_coordinates->[5]{stop}, '==', 84448,
        'The extended stop field equals 84448'
    );

    # Create an instance of
    # FoxPrimer::Model::PrimerDesign::chipPrimerDesign::twoBitToFa and make sure
    # it was created properly
    my $twobit = FoxPrimer::Model::PrimerDesign::chipPrimerDesign::twoBitToFa->new(
        genome      =>  $primer_design->genome,
        coordinates =>  $primer_design->extended_bed_coordinates,
    );
    isa_ok($twobit, 'FoxPrimer::Model::PrimerDesign::chipPrimerDesign::twoBitToFa');

    # Make sure the object can run the _get_twobit_file subroutine and returns
    # the correct data
    can_ok($twobit, '_get_twobit_file');
    my $twobit_fh = $twobit->_get_twobit_file;
    ok( -s $twobit_fh,
        'Readable 2bit file for the genome is found'
    );

    # Make sure the twobit object can run the 'create_temp_fasta' subroutine and
    # returns the correct data.
    can_ok($twobit, 'create_temp_fasta');
    my $temp_fasta_files = $twobit->create_temp_fasta;
    isa_ok($temp_fasta_files, 'ARRAY');
    isa_ok($temp_fasta_files->[5], 'File::Temp');
    open my $temp_fasta, "<", $temp_fasta_files->[5];
    while(<$temp_fasta>) {
        my $line = $_;
        chomp($line);
        if ( $line =~ /^>/ ) {
            cmp_ok($line, 'eq', '>chr4:83849-84448',
                'The FASTA header is correct'
            );
        } else {
            my @nucleotides = split(//, $line);
            cmp_ok(scalar @nucleotides, '<=', 80,
                'The FASTA file line is correctly formatted',
            );
        }
    }
    close $temp_fasta;

    # Create an instance of
    # FoxPrimer::Model::PrimerDesign::chipPrimerDesign::FIMO and make sure the
    # object was created properly
    my $fimo = FoxPrimer::Model::PrimerDesign::chipPrimerDesign::FIMO->new(
        fasta_file  =>  $temp_fasta_files->[1],
        motif       =>  $primer_design->motif
    );
    isa_ok($fimo, 'FoxPrimer::Model::PrimerDesign::chipPrimerDesign::FIMO');

    # Make sure the fimo object can run the _get_fasta_coordinates subroutine
    # and returns the correct data
    can_ok($fimo, '_get_fasta_coordinates');
    my $fasta_coordinates = $fimo->_get_fasta_coordinates;
    isa_ok($fasta_coordinates, 'HASH');
    cmp_ok($fasta_coordinates->{chromosome}, 'eq', 'chr4',
        'The chromosome field equals chr4'
    );
    cmp_ok($fasta_coordinates->{start}, '==', 76792,
        'The start field equals 76792'
    );
    cmp_ok($fasta_coordinates->{stop}, '==', 77391,
        'The stop field equals 77391'
    );

    # Make sure the fimo object can execute the subroutine '_get_motif_file'
    # which returns the path to the MEME-format motif file that corresponds to
    # the user-defined motif name
    can_ok($fimo, '_get_motif_file');
    my $motif_fh = $fimo->_get_motif_file;
    ok( -s $motif_fh, 'The motif file is readable and non-zero.');

    # Make sure the fimo object can execute the 'find_motifs' subroutine and
    # that the correct data is returned
    can_ok($fimo, 'find_motifs');
    my $motif_coordinates = $fimo->find_motifs;
    isa_ok($motif_coordinates, 'ARRAY');
    isa_ok($motif_coordinates->[0], 'HASH');
    cmp_ok($motif_coordinates->[0]{chromosome}, 'eq', 'chr4',
        'The chromosome field equals chr4'
    );
    cmp_ok($motif_coordinates->[0]{start}, '==', 76944,
        'The start field for the motif match equals 76944'
    );
    cmp_ok($motif_coordinates->[0]{stop}, '==', 76955,
        'The stop field for the motif match equals 76955'
    );

    # Create a new FASTA file extended around the motif match
    $primer_design->_set_bed_coordinates($motif_coordinates);
    $primer_design->_set_extended_bed_coordinates($primer_design->_get_extended_bed_coordinates);
    my $motif_twobit = FoxPrimer::Model::PrimerDesign::chipPrimerDesign::twoBitToFa->new(
        genome      =>  $primer_design->genome,
        coordinates =>  $primer_design->extended_bed_coordinates,
    );

    $temp_fasta_files = $motif_twobit->create_temp_fasta;

    # Make sure the primer_design object can execute the 'create_primers'
    # subroutine that is consumed from the
    # FoxPrimer::Model::PrimerDesign::chipPrimerDesign::Primer3 role. Check that
    # this subroutine returns the correct data.
    can_ok($primer_design, 'create_primers');
    my ($created_primers, $error_messages, $number_created) =
    $primer_design->create_primers(
        $primer_design->extended_bed_coordinates->[0],
        $temp_fasta_files->[0],
        $primer_design->product_size,
        $primer_design->mispriming_file,
    );
    isa_ok($created_primers, 'HASH');
    isa_ok($error_messages, 'ARRAY');
    cmp_ok($number_created, '==', 10,
        '10 primer pairs were returned',
    );

    # Create an instance of FoxPrimer::Model::PeaksToGenes and make sure the
    # instance was created correctly
    my $ptg = FoxPrimer::Model::PeaksToGenes->new(
        genome              =>  $primer_design->genome,
        primers             =>  $created_primers,
        chromosome_sizes    =>  $primer_design->chromosome_sizes,
        target_coordinates  =>  $primer_design->extended_bed_coordinates->[0],
    );
    isa_ok($ptg, 'FoxPrimer::Model::PeaksToGenes');

    # Test the _write_chromosome_sizes subroutine to make sure that File::Temp
    # object is returned
    can_ok($ptg, '_write_chromosome_sizes');
    my $temp_chr_sizes =
    $ptg->_write_chromosome_sizes($primer_design->chromosome_sizes);
    isa_ok($temp_chr_sizes, 'File::Temp');
    ok( -s $temp_chr_sizes, 'The chromosome sizes are in a temporary file.');

    # Test the _get_genomic_coordinates subroutine and make sure the data
    # is returned correctly.
    can_ok($ptg, '_get_genomic_coordinates');
    my $genomic_coordinates = $ptg->_get_genomic_coordinates($primer_design->genome);
    isa_ok($genomic_coordinates, 'File::Temp');

    # Test the _extend_and_sort_genomic_coordinates subroutine and make sure the
    # data is returned correctly
    can_ok($ptg, '_extend_and_sort_genomic_coordinates');
    my $genomic_coord_fh = $ptg->_extend_and_sort_genomic_coordinates(
        $genomic_coordinates,
        $temp_chr_sizes,
        $primer_design->genome
    );
    ok(-s $genomic_coord_fh,
        'The file created is readable.'
    );

    # Test the 'get_index' functions, which should return the file we just
    # created
    can_ok($ptg, 'get_index');
    my $other_genomic_coord_fh = $ptg->get_index(
        $primer_design->genome,
        $primer_design->chromosome_sizes
    );
    cmp_ok($genomic_coord_fh, 'eq', $other_genomic_coord_fh,
        'The files returned by both methods are the same.'
    );
    
    # Test the primers_to_bed function and make sure the data is returned
    # correctly.
    can_ok($ptg, 'primers_to_bed');
    my $primers_in_bed_format = $ptg->primers_to_bed(
        $ptg->primers,
        $ptg->target_coordinates,
    );
    isa_ok($primers_in_bed_format, 'File::Temp');

    # Test the annotate_primers subroutine and make sure the data is returned
    # correctly
    can_ok($ptg, 'annotate_primers');
    my $primers_to_genes = $ptg->annotate_primers(
        $other_genomic_coord_fh,
        $primers_in_bed_format
    );
}

done_testing();
