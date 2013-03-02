package FoxPrimer::Model::PrimerDesign::chipPrimerDesign::AvailableGenomes;
use Moose;
use namespace::autoclean;
use FindBin;
use File::Which;
use lib "$FindBin::Bin/../lib";
use FoxPrimer::Schema;
use FoxPrimer::Model::UCSC;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::PrimerDesign::chipPrimerDesign::AvailableGenomes - Catalyst Model

=head1 DESCRIPTION

This module is used to determine which genomes are available for ChIP
primer design, and to install genomes when needed.

=cut

=head1 AUTHOR

Jason R Dobson foxprimer@gmail.com

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 ucsc_genomes

This Moose object contains a Hash Ref of available genomes from UCSC.

=cut

has ucsc_genomes	=>	(
	is			=>	'ro',
	isa			=>	'HashRef[Str]',
	required	=>	1,
	default		=>	sub {
		my $self = shift;
		my $genome_info = {
			hg19	=>	1,
			hg18	=>	1,
			hg17	=>	1,
			hg16	=>	1,
			panTro3	=>	1,
			panTro2	=>	1,
			panTro1	=>	1,
			ponAbe2	=>	1,
			rheMac2	=>	1,
			calJac3	=>	1,
			calJac1	=>	1,
			mm10	=>	1,
			mm9	=>	1,
			mm8	=>	1,
			mm7	=>	1,
			rn5	=>	1,
			rn4	=>	1,
			rn3	=>	1,
			cavPor3	=>	1,
			oryCun2	=>	1,
			oviAri1	=>	1,
			bosTau7	=>	1,
			bosTau6	=>	1,
			bosTau4	=>	1,
			bosTau3	=>	1,
			bosTau2	=>	1,
			equCab2	=>	1,
			equCab1	=>	1,
			felCat4	=>	1,
			felCat3	=>	1,
			canFam3	=>	1,
			canFam2	=>	1,
			canFam1	=>	1,
			monDom5	=>	1,
			monDom4	=>	1,
			monDom1	=>	1,
			ornAna1	=>	1,
			galGal4	=>	1,
			galGal3	=>	1,
			galGal2	=>	1,
			taeGut1	=>	1,
			xenTro3	=>	1,
			xenTro2	=>	1,
			xenTro1	=>	1,
			danRer7	=>	1,
			danRer6	=>	1,
			danRer5	=>	1,
			danRer4	=>	1,
			danRer3	=>	1,
			fr3	=>	1,
			fr2	=>	1,
			fr1	=>	1,
			gasAcu1	=>	1,
			oryLat2	=>	1,
			dm3	=>	1,
			dm2	=>	1,
			dm1	=>	1,
			ce10	=>	1,
			ce6	=>	1,
			ce4	=>	1,
			ce2	=>	1,
			ce10	=>	1,
		};
		return $genome_info;
	},
);

=head2 genomes_to_install

This Moose object contains an Array Ref of genomes that the user wishes to
install.

=cut

has	genomes_to_install	=>	(
	is			=>	'ro',
	isa			=>	'ArrayRef'
);

=head2 _chip_genomes_schema

This Moose object contains the Schema for connecting to the ChIP Genomes
FoxPrimer database

=cut

has _chip_genomes_schema	=>	(
	is			=>	'ro',
	isa			=>	'FoxPrimer::Schema',
	default		=>	sub {
		my $self = shift;
		my $dsn = "dbi:SQLite:$FindBin::Bin/../db/chip_genomes.db";
		my $schema = FoxPrimer::Schema->connect($dsn, '', '', '');
		return $schema;
	},
	required	=>	1,
	reader		=>	'chip_genomes_schema',
);

=head2 installed_genomes

This subroutine returns an Array Ref of installed genomes that is used by
the Template Toolkit to parse into a drop-down list of genomes that the
user can design ChIP primers for.

=cut

sub installed_genomes {
	my $self = shift;

	# Pre-declare an Array Ref to hold the genomes installed in the user's
	# database.
	my $installed_genomes = [];

	# Create a genomes result set
	my $genomes_result_set =
	$self->chip_genomes_schema->resultset('Genome');

	# Fetch all of the results using the 'all' method
	my @all_genomes_installed = $genomes_result_set->all;

	# Iterate through the genomes, adding the genome string to the
	# installed_genomes Array Ref.
	foreach my $installed_genome (@all_genomes_installed) {
		push(@$installed_genomes, $installed_genome->genome);
	}

	return $installed_genomes;
}

=head2 install_chip_genomes

This subroutine is called by an external script (typically by the
administrator) to install genomes for the design of ChIP primers.

=cut

sub install_chip_genomes {
	my $self = shift;

	# Determine whether the genomes defined by the user are valid UCSC
	# genome strings and have RefSeq annotation associated with them.
	#
	# Pre-declare an Array Ref to hold valid genome symbols.
	my $valid_genomes_to_install = [];

	# Iterate through the genomes_to_install
	foreach my $genome_to_test (@{$self->genomes_to_install}) {
		if ( $self->ucsc_genomes->{$genome_to_test} ) {
			push(@$valid_genomes_to_install, $genome_to_test);
		} else {
			print "The following genome can not be installed: " .
			"$genome_to_test\n";
		}
	}

	# If there were valid genomes found, install these. Otherwise, return a
	# message to the user.
	if (@$valid_genomes_to_install) {
		
		# Ensure that wget is installed.
		my $wget_path = which('wget');
		chomp($wget_path);
		unless ($wget_path) {
			die "You must have wget installed to fetch 2bit files from" .
			" UCSC\n";
		}

		# Ensure that MySQL is installed
		my $mysql_path = which('mysql');
		chomp($mysql_path);
		unless ($mysql_path) {
			die "You must have mysql installed to interact with the UCSC" .
			" MySQL tables\n";
		}

		# Iterate through the genomes_to_install and fetch the 2bit file
		# and gene body coordinates from UCSC, storing the relevant
		# information in the ChIP genomes database.
		foreach my $genome_to_install (@$valid_genomes_to_install) {

			# Insert the current genome into the genomes table
			my $genome_insert =
			$self->chip_genomes_schema->resultset('Genome')->find_or_new({
					genome	=>	$genome_to_install
				}
			);

			if ( ! $genome_insert->in_storage ) {
				$genome_insert->insert;
			}

			# Create a string for the location of the 2bit file
			my $twobit_fh =
			"$FindBin::Bin/../root/static/files/twobit_genomes/$genome_to_install.2bit";

			# Create a string for wget execution
			my $wget_execution = $wget_path . " -O $twobit_fh " .
			"http://hgdownload.cse.ucsc.edu/goldenPath/" .
			$genome_to_install . "/bigZips/" . $genome_to_install .
			".2bit";

			# Execute the wget string
			print "\nNow fetching the 2bit file for $genome_to_install\n";
#			`$wget_execution`;

			# Ensure that the 2bit file has been downloaded
			unless ( -r $twobit_fh ) {
				die "\nUnable to save the $genome_to_install 2bit file\n";
			}

			# Add the 2bit path to the database
			$self->chip_genomes_schema->resultset('Twobit')->populate(
				[
					{
						path	=>	$twobit_fh,
						genome	=>	$genome_insert->id
					}
				]
			);

			# Connect to the UCSC MySQL database.
			my $schema = FoxPrimer::Model::UCSC->connect(
				'dbi:mysql:host=genome-mysql.cse.ucsc.edu;database=' .
				$genome_to_install, "genome"
			);

			# Define the columns to fetch from the UCSC MySQL browser
			my $column_names = [
				"chrom",
				"txStart",
				"txEnd",
				"cdsStart",
				"cdsEnd",
				"exonCount",
				"exonStarts",
				"exonEnds",
				"name",
				"strand",
			];

			# Create a string for the DBI call
			my $col_string = join(", ", @$column_names);


			# Extract all of the RefSeq gene coordinates
			my $refseq = $schema->storage->dbh_do(
				sub {
					my ($storage, $dbh, @args) = @_;
					$dbh->selectall_hashref("SELECT $col_string FROM refGene",
						["name"]);
				},
			);

			# Pre-declare an Array Ref to hold the insert statements for
			# the gene body coordinates
			my $gene_body_insert = [];

			# Iterate through the gene body coordinates, creating insert
			# statements and adding them to the gene_body_coordinates Array
			# Ref of insert statements
			foreach my $accession (keys %$refseq) {
				push(@$gene_body_insert,
					{
						genome		=>	$genome_insert->id,
						accession	=>	$accession,
						chromosome	=>	$refseq->{$accession}{chrom},
						txstart		=>	$refseq->{$accession}{txStart},
						txend		=>	$refseq->{$accession}{txEnd},
						strand		=>	$refseq->{$accession}{strand}
					}
				);
			}

			# Insert the gene body information into the database
			$self->chip_genomes_schema->resultset('Genebody')->populate(
				$gene_body_insert
			);

			# Get the chromosome sizes file from UCSC
			my $raw_chrom_sizes = $schema->storage->dbh_do(
				sub {
					my ($storage, $dbh, @args) = @_;
					$dbh->selectall_hashref("SELECT chrom, size FROM chromInfo", ["chrom"]);
				},
			);

			# Pre-declare a Hash Ref to hold the final information for the chromosome sizes
			my $chrom_sizes = {};

			# Parse the chromosome sizes file into an easier to use form
			foreach my $chromosome (keys %$raw_chrom_sizes) {
				$chrom_sizes->{$chromosome} = $raw_chrom_sizes->{$chromosome}{size};
			}

			# Define a string for the location of the chromosome sizes file
			my $chrom_sizes_fh =
			"$FindBin::Bin/../root/static/files/chromosome_sizes_files/$genome_to_install.chrom.sizes";

			# Convert the chromosome sizes information into an Array Ref for easier
			# printing
			my $chromsome_sizes_array = [];
			foreach my $chr (keys %$chrom_sizes) {
				push(@$chromsome_sizes_array, 
					join("\t", $chr, $chrom_sizes->{$chr})
				);
			}

			# Print the chromosome sizes to the file
			open my $chrom_sizes_file, ">", $chrom_sizes_fh or die 
			"Could not write to $chrom_sizes_fh $!\n";
			print $chrom_sizes_file join("\n", @$chromsome_sizes_array);
			close $chrom_sizes_file;

			# Add the chromosome sizes file string to the database
			$self->chip_genomes_schema->resultset('Chromosomesize')->populate(
				[
					{
						genome	=>	$genome_insert->id,
						path	=>	$chrom_sizes_fh
					}
				]
			);
		}
	} else {
		print "\nNo valied genomes were entered, so no installation " .
		"occured\n\n";
	}
}

__PACKAGE__->meta->make_immutable;

1;
