#
#===============================================================================
#
#         FILE: PeaksToGenes_Index_Maker.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Jason R. Dobson (JRD), dobson187@gmail.com
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 08/25/2012 08:23:16 AM
#     REVISION: ---
#===============================================================================

package PeaksToGenes_Index_Maker;
use strict;
use warnings;
use Moose;
with 'MooseX::Getopt';

has genome_name	=>	(
	is				=>	'rw',
	isa				=>	'Str',
	default			=>	sub { die "You must enter a genome name\n"; },
	documentation	=>	"This is the base name that will be placed in the front of each index file created",
	lazy			=>	1,
);

has chromosome_sizes_file	=>	(
	is				=>	'rw',
	isa				=>	'Str',
	default			=>	sub { die "You must enter the full path to the chromosome sizes file for your genome\n"; },
	documentation	=>	"A tab-delimited file of two colums. The first column is the chromosome name, while the second file is the length (in bases) of that chromosome.",
	lazy			=>	1,
);

has _chromosome_sizes	=>	(
	is				=>	'rw',
	isa				=>	'HashRef[Int]',
	default			=>	sub {
		my $self = shift;
		my $chromosome_sizes_fh = $self->chromosome_sizes_file;
		# Pre-declare a HashRef to hold the chromosome sizes
		my $chromosome_sizes = {};
		open my $chromosome_sizes_file, "<", $chromosome_sizes_fh or die "Could not read from $chromosome_sizes_fh. Please check the permissions on this file. $!\n";
		while (<$chromosome_sizes_file>) {
			my $line = $_;
			chomp ($line);
			my ($chr, $length) = split(/\t/, $line);
			$chromosome_sizes->{$chr} = $length;
		}
		return $chromosome_sizes;
	},
	lazy			=>	1,
);

has promoter_file	=>	(
	is				=>	'rw',
	isa				=>	'Str',
	default			=>	sub { die "You must enter the full path to a bed file corresponding to the promoter coordinates of your genome\n"; },
	documentation	=>	"A BED-file format containing the coordinates of the 2.5Kb promoters for your genome. This file should already be named with the root name of the genome you have chosen.",
	lazy			=>	1,
);

has downstream_file	=>	(
	is				=>	'rw',
	isa				=>	'Str',
	default			=>	sub { die "You must enter the full path to a bed file corresponding to the 2.5Kb downstream coordiantes of your genome\n"; },
	documentation	=>	"A BED-file format containing the coordinates of the 2.5Kb downstream regions for your genome. This file should already be named with the root name of the genome you have chosen.",
	lazy			=>	1,
);
1;
