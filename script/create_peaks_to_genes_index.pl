#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: create_peaks_to_genes_index.pl
#
#        USAGE: ./create_peaks_to_genes_index.pl  
#
#  DESCRIPTION: This is an experimental script to create PeaksToGenes index files
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Jason R. Dobson (JRD), dobson187@gmail.com
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 08/25/2012 01:55:56 AM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;
use Data::Dumper;
use lib 'script';
use PeaksToGenes_Index_Maker;

my $index_maker = PeaksToGenes_Index_Maker->new_with_options();

# Pre-declare a Hash-ref for the different files that will be 
# created
my $files_to_create	=	{
	Upstream	=>	[
		5,
		10,
		25,
		50,
		100,
	],
	Downstream	=>	[
		5,
		10,
		25,
		50,
		100,
	],
};

my $created_files = {
	Upstream	=>	{
		5	=>	[],
		10	=>	[],
		25	=>	[],
		50	=>	[],
		100	=>	[],
	},
	Downstream	=>	{
		5	=>	[],
		10	=>	[],
		25	=>	[],
		50	=>	[],
		100	=>	[],
	},
};

my $base_numbers = {
	5	=>	2.5,
	10	=>	5,
	25	=>	10,
	50	=>	25,
	100	=>	50
};

foreach my $direction ( keys %$files_to_create ) {
	# Declare a string to hold the file handle of the
	# base file for the direction. This is either the
	# promoter file or the downstream file.
	my $base_fh = '';
	if ( $direction eq 'Upstream' ) {
		$base_fh = $index_maker->promoter_file;
	} elsif ( $direction eq 'Downstream' ) {
		$base_fh = $index_maker->downstream_file;
	}
	for (my $i = 0; $i < @{$files_to_create->{$direction}}; $i++) {
		my $base_number = $base_numbers->{$files_to_create->{$direction}[$i]};
		open my $base_file, "<", $base_fh or die "Could not read form $base_fh $!\n";
		while (<$base_file>) {
			my $line = $_;
			chomp ($line);
			my ($chr, $start, $stop, $name, $score, $strand) = split(/\t/, $line);
			my $extended_start = 0;
			my $extended_stop = 0;
			if ( $direction eq 'Upstream' ) {
				($extended_start, $extended_stop) = upstream_extension($start, $stop, $base_number, $files_to_create->{$direction}[$i], $strand);
			} elsif ( $direction eq 'Downstream' ) {
				($extended_start, $extended_stop) = downstream_extension($start, $stop, $base_number, $files_to_create->{$direction}[$i], $strand);
			}
			# Check to ensure that the these extended coordinates are valid based on the chromosome sizes
			# for the genome
			if (($extended_start >= 1) && ($extended_start <= $index_maker->_chromosome_sizes->{$chr}) &&
				($extended_stop >= 1) && ($extended_stop <= $index_maker->_chromosome_sizes->{$chr})) {
				my $accession;
				if ( $name =~ /(\w\w_\d+)_/ ) {
					$accession = $1;
				}
				push (@{$created_files->{$direction}{$files_to_create->{$direction}[$i]}}, join("\t", $chr,
						$extended_start, $extended_stop, $accession, $score, $strand)
				);
			}
		}
	}
}

foreach my $direction (keys %$created_files) {
	foreach my $interval ( keys %{$created_files->{$direction}} ) {
		my $out_fh = "root/static/files/" . $index_maker->genome_name . "_Index/";
		die "You must enter the name of a genome which already has the directory structure created\n" unless (-d $out_fh);
		$out_fh .= $index_maker->genome_name . "_$interval" . "K_$direction.bed";
		open my $out, ">", $out_fh or die "Could not write to $out_fh $!\n";
		print $out join("\n", @{$created_files->{$direction}{$interval}});
	}
}

sub upstream_extension {
	my ($start, $stop, $base_number, $extension_number, $strand) = @_;
	$base_number *= 1000;
	$extension_number *= 1000;
	my $extended_start = 0;
	my $extended_stop = 0;
	if ( $strand eq '+' ) {
		$extended_start = $stop - $extension_number;
		$extended_stop = $extended_start + $base_number;
	} elsif ( $strand eq '-' ) {
		$extended_stop = $start + $extension_number;
		$extended_start = $extended_stop - $base_number;
	}
	return ($extended_start, $extended_stop);
}

sub downstream_extension {
	my ($start, $stop, $base_number, $extension_number, $strand) = @_;
	$base_number *= 1000;
	$extension_number *= 1000;
	my $extended_start = 0;
	my $extended_stop = 0;
	if ( $strand eq '+' ) {
		$extended_stop = $start + $extension_number;
		$extended_start = $extended_stop - $base_number;
	} elsif ( $strand eq '-' ) {
		$extended_start = $stop - $extension_number;
		$extended_stop = $extended_start + $base_number;
	}
	return ($extended_start, $extended_stop);
}
