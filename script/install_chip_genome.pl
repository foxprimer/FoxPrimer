#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FoxPrimer::Model::PrimerDesign::chipPrimerDesign::AvailableGenomes;

# Store the genomes the user has defined for installation in a local Array.
my @genomes_to_install = @ARGV;

# Make sure that the user has defined genomes to install.
unless (@genomes_to_install) {
	die "\nPlease enter a series of genomes to install in the form of: " .
	"'install_chip_genome.pl dm3 mm9 mm10 hg19'.\n\n";
}

# Create an instance of
# FoxPrimer::Model::PrimerDesign::chipPrimerDesign::AvailableGenomes
my $available_genomes =
FoxPrimer::Model::PrimerDesign::chipPrimerDesign::AvailableGenomes->new(
	genomes_to_install	=>	\@genomes_to_install
);

# Run the 'install_chip_genomes' subroutine to install the user-defined
# genomes.
$available_genomes->install_chip_genomes;
