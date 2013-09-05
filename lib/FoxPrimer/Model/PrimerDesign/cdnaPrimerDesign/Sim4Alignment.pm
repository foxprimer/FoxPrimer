package FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Sim4Alignment;
use Moose;
use Carp;
use IPC::Run3;
use File::Which;
use File::Temp;
use autodie;
use FindBin;
use lib "$FindBin::Bin/../lib";
use namespace::autoclean;

=head1 NAME

FoxPrimer::Model::PrimerDesign::cdnaPrimerDesign::Sim4Alignment - Catalyst Model

=head1 DESCRIPTION

This module is given two FASTA-format files that must be defined at object
creation. One corresponds to the cDNA sequence, while the other corresponds to
the genomic DNA sequence. This module then runs sim4 to find the alignments and
parses the results into a Hash Ref.

=head1 AUTHOR

Jason R Dobson foxprimer@gmail.com

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 sim4_path

This Moose attribute holds the path to sim4. This attribute is dynamically
defined; therefore, sim4 must be in the user's $PATH.

=cut

has sim4_path   =>  (
    is          =>  'ro',
    isa         =>  'Str',
    predicate   =>  'has_sim4_path',
    writer      =>  '_set_sim4_path',
);

before  'sim4_path' =>  sub {
    my $self = shift;
    unless ($self->has_sim4_path) {
        $self->_set_sim4_path($self->_get_sim4_path);
    }
};

=head2 _get_sim4_path

This private subroutine is dynamically run to define the path to sim4. If sim4
cannot be found, the program ceases execution.

=cut

sub _get_sim4_path  {
    my $self = shift;
    my $sim4_path = which('sim4');
    chomp($sim4_path);
    $sim4_path ? return $sim4_path : croak
    "\n\nsim4 was not found in the \$PATH. Please check that it is installed.\n\n";
}

=head2 cdna_fh

This Moose object holds the File::Temp object of the cDNA FASTA format sequence
file.

=cut

has cdna_fh	=>	(
	is		=>	'ro',
	isa		=>	'File::Temp'
);

=head2 genomic_dna_fh

This Moose object holds the File::Temp object of the genomic DNA FASTA format
sequence file.

=cut

has genomic_dna_fh	=>	(
	is		=>	'ro',
	isa		=>	'File::Temp'
);

=head2 sim4_alignment

This subroutine is the main subroutine which creates s
Bio::Tools::Run::Alignment::Sim4 object with the supplied files. Then this
subroutine parses the results returned from Sim4 into a Hash Ref and
returns these coordinates.

=cut

sub sim4_alignment {
	my $self = shift;

    # Define a string to be executed by IPC::Run3
    my $sim4_cmd = join(' ', 
        $self->sim4_path, 
        $self->cdna_fh, 
        $self->genomic_dna_fh,
        'R=0'
    );

    # Create a new File::Temp object to capture the sim4 output.
    my $sim4_outfh = File::Temp->new();

    # Run the sim4 command and capture the output
    run3 $sim4_cmd, undef, $sim4_outfh, undef;

    # Pre-declare a Hash Ref to hold the results of the sim4 alignment
    my $coordinates = {};

    # Pre-define integers for the alignment number, exon number and intron
    # number
    my $alignment_number = 0;
    my $exon_number = 0;
    my $intron_number = 0;

    # Pre-declare an integer value for the length of the cDNA and for the length
    # of the genomic DNA
    my $cdna_length = 0;
    my $genomic_dna_length = 0;

    # Open the sim4 results file, iterate through the results, parse into the
    # coordinates Hash Ref
    open my $sim4_file, '<', $sim4_outfh;
    while(<$sim4_file>) {
        my $line = $_;
        chomp($line);
        
        # Matching the seq1 variable indicates a new alignment
        if ( $line =~ /^seq1/ ) {
            # Increase the alignment number
            $alignment_number++;
            
            # Use regular expression to get the length
            if ( $line =~ /,\s+(\d+)\sbp/) {
                $cdna_length = $1;
            }
        } elsif ( $line =~ /^seq2/ ) {
            # Use regular expression to get the length
            if ( $line =~ /,\s+(\d+)\sbp/) {
                $genomic_dna_length = $1;
            }
        } # Use regex to match start-end (start-end) percent matched and continued match
        elsif ( $line =~ qr/(\d+)-(\d+)\s+\((\d+)-(\d+)\)\s+(\d+)%\s+->/ ) { 

            # Increase the exon number
            $exon_number++;

            # Add the values to the coordinates Hash Ref
            $coordinates->{'Alignment ' . $alignment_number}{'Exon ' .
            $exon_number}{'mRNA'}{'Start'} = $1;
            $coordinates->{'Alignment ' . $alignment_number}{'Exon ' .
            $exon_number}{'mRNA'}{'Stop'} = $2;
            $coordinates->{'Alignment ' . $alignment_number}{'Exon ' .
            $exon_number}{'Genomic'}{'Start'} = $3;
            $coordinates->{'Alignment ' . $alignment_number}{'Exon ' .
            $exon_number}{'Genomic'}{'End'} = $4;

            # If the current exon is not the first, calculate the intron size
            if ( $exon_number > 1 ) {

                # Increase the intron number
                $intron_number++;

                $coordinates->{'Alignment ' . $alignment_number}{'Intron ' .
                $intron_number}{'Size'} = $coordinates->{'Alignment ' .
                $alignment_number}{'Exon ' .
                ($intron_number+1)}{'Genomic'}{'Start'} -
                $coordinates->{'Alignment ' . $alignment_number}{'Exon ' .
                $intron_number}{'Genomic'}{'End'};
            }
        } # Use regex to match start-end (start-end) percent matched for terminal exon
        elsif ( $line =~ qr/(\d+)-(\d+)\s+\((\d+)-(\d+)\)\s+(\d+)%$/ ) {

            # Increase the exon number
            $exon_number++;

            # Add the values to the coordinates Hash Ref
            $coordinates->{'Alignment ' . $alignment_number}{'Exon ' .
            $exon_number}{'mRNA'}{'Start'} = $1;
            $coordinates->{'Alignment ' . $alignment_number}{'Exon ' .
            $exon_number}{'mRNA'}{'Stop'} = $2;
            $coordinates->{'Alignment ' . $alignment_number}{'Exon ' .
            $exon_number}{'Genomic'}{'Start'} = $3;
            $coordinates->{'Alignment ' . $alignment_number}{'Exon ' .
            $exon_number}{'Genomic'}{'End'} = $4;

            # Increase the intron number and calculate the intron size
            $intron_number++;

            $coordinates->{'Alignment ' . $alignment_number}{'Intron ' .
            $intron_number}{'Size'} = $coordinates->{'Alignment ' .
            $alignment_number}{'Exon ' .
            ($intron_number+1)}{'Genomic'}{'Start'} - $coordinates->{
            'Alignment ' . $alignment_number}{'Exon ' .
            $intron_number}{'Genomic'}{'End'}; 
        }
    }
    close $sim4_file;


    # Store the number of exons in the coordinates Hash Ref.
    $coordinates->{'Alignment ' . $alignment_number}{'Number of Exons'} =
    $exon_number;

    # Store the number of alignments found in the coordinates Hash Ref.
    $coordinates->{'Number of Alignments'} = $alignment_number;

    return $coordinates;

#	# Create a Bio::Tools::Run::Alignment::Sim4 object
#	my $sim4 = Bio::Tools::Run::Alignment::Sim4->new(
#		cdna_seq		=>	$self->cdna_fh,
#		genomic_seq		=>	$self->genomic_dna_fh,
#	);
#
#	# Run Sim4, which returns the possible alignments in an Array
#	my @exon_sets = $sim4->align;
#
#	# Pre-declare a Hash Ref to hold the coordinates found in the
#	# alignments from Sim4.
#	my $coordinates = {};
#
#	# Define an integer for the number of alignments found by Sim4
#	my $alignment_iterator = 0;
#
#	# Iterate through the alignments found by Sim4. Parsing the coordinates
#	# into the coordinates Hash Ref.
#	foreach my $set (@exon_sets) {
#
#		# Increase the alignment iterator
#		$alignment_iterator++;
#
#		# Define an integer to use for iteration through the number of
#		# exons found by Sim4.
#		my $exon_iterator = 0;
#
#		# Iterate through the exons defined by Sim4.
#		foreach my $exon ( $set->sub_SeqFeature ) {
#
#			# Increase the exon iterator
#			$exon_iterator++;
#
#			# Store the genomic DNA start position for this exon and
#			# alignment,
#			$coordinates->{'Alignment ' . $alignment_iterator}{'Exon ' .
#				$exon_iterator}{'Genomic'}{'Start'} = $exon->start;
#
#			# Store the genomic DNA stop position for this exon and
#			# alignment.
#			$coordinates->{'Alignment ' . $alignment_iterator}{'Exon ' .
#				$exon_iterator}{'Genomic'}{'End'} = $exon->end;
#
#			# Store the cDNA start position for this exon and alignment
#			$coordinates->{'Alignment ' . $alignment_iterator}{'Exon ' .
#				$exon_iterator}{'mRNA'}{'Start'} = $exon->est_hit->start;
#
#			# Store the cDNA stop position for this exon and alignment
#			$coordinates->{'Alignment ' . $alignment_iterator}{'Exon ' .
#				$exon_iterator}{'mRNA'}{'Stop'} = $exon->est_hit->end;
#		}
#
#		# Store the number of exons in the coordinates Hash Ref.
#		$coordinates->{'Alignment ' . $alignment_iterator}{
#		'Number of Exons'} = $exon_iterator;
#
#		# Calculate the number of sizes of the introns defined for the
#		# current alignment by Sim4
#		for ( my $intron_iterator = 1; $intron_iterator <
#			($exon_iterator-1); $intron_iterator++ ) {
#
#			# Store the size of the intron in the coordinates Hash Ref.
#			$coordinates->{'Alignment ' . $alignment_iterator}{'Intron ' .
#				$intron_iterator}{'Size'} = $coordinates->{'Alignment ' .
#				$alignment_iterator}{'Exon ' .
#				($intron_iterator+1)}{'Genomic'}{'Start'} -
#				$coordinates->{'Alignment ' . $alignment_iterator}{'Exon ' .
#				$intron_iterator}{'Genomic'}{'End'};
#		}
#
#		# Store the number of alignments found in the coordinates Hash Ref.
#		$coordinates->{'Number of Alignments'} = $alignment_iterator;
#	}
#
#	return $coordinates;
}

__PACKAGE__->meta->make_immutable;

1;
