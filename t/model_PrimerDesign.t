use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

# Make sure that we can use the FoxPrimer::Model::PrimerDesign module.
BEGIN { use_ok 'FoxPrimer::Model::PrimerDesign' }

# Create a FoxPrimer::Model::PrimerDesign object
my $primer_design_object = FoxPrimer::Model::PrimerDesign->new(
	accessions_string	=>	'NM_001015051.3,NM_001024630,NM_99119',
);

# Make sure that the primer_design_object has been created correctly.
isa_ok($primer_design_object, 'FoxPrimer::Model::PrimerDesign');

# Make sure that the gene2accession_schema is a FoxPrimer::Schema object.
can_ok($primer_design_object, 'gene2accession_schema');
my $gene2accession_schema = $primer_design_object->gene2accession_schema;
isa_ok($gene2accession_schema, 'FoxPrimer::Schema');

# Make sure that the primer design object can execute the
# valid_refseq_accessions subroutine
can_ok($primer_design_object, 'valid_refseq_accessions');

# Run the valid_refseq_accessions subroutine with two correct RefSseq mRNA
# accession string (one with the version modifier, and one without), and
# one invalid RefSeq mRNA accession.
my ($error_messages, $accessions_to_design) =
$primer_design_object->valid_refseq_accessions;

# Make sure that the valid_refseq_accessions subroutine returns two Array
# Refs
isa_ok($error_messages, 'ARRAY');
isa_ok($accessions_to_design, 'ARRAY');

# Make sure that one and only one error message is returned.
cmp_ok(@$error_messages, '==', 1, 
	'There was one error message correctly returned'
);
cmp_ok(@$error_messages, '!=', 2, 
	'There was one error message correctly returned'
);

# Make sure that each item in the accessions_to_design Array Ref is a Hash
# Ref
foreach my $accession_to_design (@$accessions_to_design) {
	isa_ok($accession_to_design, 'HASH');
}

# Create an instance of FoxPrimer::Model::PrimerDesign for the purpose of
# testing to make sure that the 'valid_bed_file' will appropriately find
# errors in a BED-format file for a given genome and return the
# properly-formatted information in the form of an Array Ref of Hash Refs.
# 
# Define a scalar string for the file to which temporary BED coordinates
# will be written.
my $temp_bed_fh = "$FindBin::Bin/temp_bed.bed";

# Write a series of BED-format coordinates to file
open my $temp_bed_file, ">", $temp_bed_fh or die "Could not read from " .
$temp_bed_fh . "$!\n";
print $temp_bed_file join("\n",
	join("\t", 'chrX', '473', '500'),
	join("\t", 'chrU', '473', '400'),
	join("\t", 'chrX', '473', '22422827'),
	join("\t", 'chrX', '473', '22422828'),
	join("\t", 'chrX', '0', '500'),
	join("\t", 'chrR', '473', '500'),
	join("\t", 'chrX', '473', '500'),
	join("\t", 'chrX', '473', '500'),
	join("\t", 'chrX', '473', '500'),
	join("\t", 'chrX', '473', '500'),
	join("\t", 'chrX', '473', '500'),
	join("\t", 'chrX', '473', '500'),
	join("\t", 'chrX', '473', '500'),
	join("\t", 'chrX', '473', '500'),
	join("\t", 'chrX', '473', '500'),
	join("\t", 'chrX', '473', '500'),
);
close $temp_bed_file;

my $bed_file_test = FoxPrimer::Model::PrimerDesign->new(
	genome						=>	'dm3',
	chip_primers_coordinates	=>	$temp_bed_fh,
);

# Make sure the bed_file_test object was created correctly.
isa_ok($bed_file_test, 'FoxPrimer::Model::PrimerDesign');

# Make sure that the bed_file_test object can execute the 'valid_bed_file'
# subroutine.
can_ok($bed_file_test, 'valid_bed_file');

# Execute the 'valid_bed_file' subroutine, which should return an Array Ref
# of errors found in the file and an Array Ref of Hash Refs of genomic
# coordinates.
my ($bed_file_errors, $bed_file_coordinates) =
$bed_file_test->valid_bed_file;

isa_ok($bed_file_errors, 'ARRAY');
isa_ok($bed_file_coordinates, 'ARRAY');
isa_ok($bed_file_coordinates->[0], 'HASH');
cmp_ok(@$bed_file_errors, '==', 6, 
	'The correct number of errors were found'
);
cmp_ok(@$bed_file_coordinates, '==', 10,
	'The correct number of coordinates were returned'
);

# Remove the temporary BED file.
unlink($temp_bed_fh);

done_testing();
