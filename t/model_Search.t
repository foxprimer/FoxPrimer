use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";


BEGIN { use_ok 'FoxPrimer::Model::Search' }

# Create a FoxPrimer::Model::Search object
my $search = FoxPrimer::Model::Search->new(
    search_string   =>  
    'NM_001111021.1, NM_001111021, NM_001014, jd_429234 Runx2 pan Pan'
);

# Make sure the object was created properly.
isa_ok($search, 'FoxPrimer::Model::Search');

# Make sure the search object can execute the 'find_full_accessions'
# subroutine.
can_ok($search, 'find_full_accessions');

# Run the 'find_full_accessions' subroutine, which should return an Array
# Ref of full RefSeq mRNA accessions.
my $full_accessions = $search->find_full_accessions;

# Make sure the object returned is an Array Ref and contains the
# appropriate information.
isa_ok($full_accessions, 'ARRAY');
cmp_ok($full_accessions->[0], 'eq', 'NM_001111021.1',
    'The full accession root was correctly found'
);
cmp_ok($full_accessions->[1], 'eq', 'NM_001111021.1',
    'The full accession root was correctly found'
);
cmp_ok($full_accessions->[2], 'eq', 'NM_001014.4',
    'The full accession root was correctly found'
);
cmp_ok(@$full_accessions, '==', 3,
    'The correct number of accession roots were found'
);

done_testing();
