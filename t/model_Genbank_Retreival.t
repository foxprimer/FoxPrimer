use strict;
use warnings;
use FindBin;
use Data::Dumper;
use lib "$FindBin::Bin/../lib";

use Test::More;


BEGIN { 
    use_ok 'FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign';

    # Create an instance of FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign to
    # use the functions from
    # FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::GenBankRetreiver that
    # are consumed
    my $primer_design = FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign->new();
    isa_ok($primer_design, 'FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign');

    # Test the 'get_cdna_object' function
    can_ok($primer_design, 'get_cdna_object');
    my ($cdna_object, $cdna_seq, $desc) = $primer_design->get_cdna_object(442628857);
    print $cdna_seq, "\n", $desc, "\n";

    # Test the 'get_genomic_dna_object' subroutine
    can_ok($primer_design, 'get_genomic_dna_object');
    my $gdna_object = $primer_design->get_genomic_dna_object(
        116010444, 22165719, 22169142, '-'
    );
    open my $gdna_file, '<', $gdna_object;
    while(<$gdna_file>) {
        print $_;
    }
    close $gdna_file;
}

done_testing();
