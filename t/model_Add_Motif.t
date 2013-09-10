#
#===============================================================================
#
#         FILE: model_Add_Motif.t
#
#  DESCRIPTION: This script tests the functions of FoxPrimer::Model::AddMotif
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Jason R. Dobson (), Jason_Dobson@brown.edu
# ORGANIZATION: Center for Computational Molecular Biology
#      VERSION: 1.0
#      CREATED: 09/09/2013 15:23:40
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use File::Temp;
use autodie;

BEGIN{
    use_ok('FoxPrimer::Model::AddMotif');

    my $motifs = {
        valid =>
        "/Users/jason/Documents/Larschan_Lab/define_clamp_motif_positions_dm3/MEME_Motifs/6zf_95th_Percentile/meme.txt",
        invalid => "$FindBin::Bin/../S2.GFP.RNAi.CG1832_peaks_fdr_0.01.txt",
    };

    foreach my $motif_type ( keys %{$motifs} ) {

        # Create a File::Temp object and write the contents of the file
        my $file_temp = File::Temp->new();

        # Define an Array Ref to hold the lines
        my $temp_array = [];

        open my $file, "<", $motifs->{$motif_type};
        while(<$file>) {
            my $line = $_;
            chomp($line);
            push(@{$temp_array}, $line);
        }
        close $file;

        # Print to the temp file
        open my $temp_file, ">", $file_temp;
        print $temp_file join("\n", @{$temp_array});
        close $temp_file;

        # Create an instance of FoxPrimer::Model::AddMotif and make sure it was
        # created properly
        my $add_motif = FoxPrimer::Model::AddMotif->new(
            motif_name  =>  $motif_type,
            motif_file  =>  $file_temp,
        );

        isa_ok($add_motif, 'FoxPrimer::Model::AddMotif');

        # Test the 'add_motif' function
        can_ok($add_motif, 'add_motif');
        my $added_ok = $add_motif->add_motif;

        if ( $motif_type eq 'valid' ) {
            cmp_ok($added_ok, '==', 1,
                'The motif uploaded is valid'
            );
        } else {
            cmp_ok($added_ok, '==', 0,
                'The motif uploaded is not valid'
            );
        }
    }
}

done_testing();
