use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Data::Dumper;
use Test::More;


BEGIN { 
    use_ok 'FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Sim4Alignment';
    use_ok 'FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign';

    # Create an instance of FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign to
    # get a File::Temp object for the cDNA and genomic DNA.
    my $primer_design = FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign->new();
    my ($cdna_obj, $gdna_obj, $mrna_desc, $cdna_seq) = $primer_design->get_objects(
        442628857, 116010444, 22165719, 22169142, '-'
    );
    isa_ok($cdna_obj, 'File::Temp');
    isa_ok($gdna_obj, 'File::Temp');

    # Create an instance of
    # FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Sim4Alignment and make
    # sure the object was created properly.
    my $sim4 = FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Sim4Alignment->new(
        cdna_fh         =>  $cdna_obj,
        genomic_dna_fh  =>  $gdna_obj,
    );
    isa_ok($sim4, 'FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Sim4Alignment');
    like($sim4->sim4_path, qr/sim4$/, 'Path to sim4 found');

    # Test the 'sim4_alignment' function
    can_ok($sim4, 'sim4_alignment');
    my $sim4_alignment = $sim4->sim4_alignment;
    isa_ok($sim4_alignment, 'HASH');
    cmp_ok($sim4_alignment->{'Alignment 1'}{'Number of Exons'}, '==', 7,
        '7 Exons were found.'
    );
    cmp_ok($sim4_alignment->{'Alignment 1'}{'Intron 3'}{Size}, '==', 54,
        'Intron 3 is 54bp long.'
    );
    cmp_ok($sim4_alignment->{'Alignment 1'}{'Exon 7'}{Genomic}{End}, '==', 3177,
        'The genomic position of the 3\'-end of exon 7 is 3177.'
    );
}

done_testing();
