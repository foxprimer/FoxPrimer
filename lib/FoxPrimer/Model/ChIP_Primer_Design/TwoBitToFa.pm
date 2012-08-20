package FoxPrimer::Model::ChIP_Primer_Design::TwoBitToFa;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Model';

=head1 NAME

FoxPrimer::Model::ChIP_Primer_Design::TwoBitToFa - Catalyst Model

=head1 DESCRIPTION

This Catalyst Model is part of the ChIP primer design methods.

This module provides the methods to extract genomic sequence from
a 2bit file using the Kent source utility twoBitToFa and writes
the sequence to a temporary Fasta-format file.

=head1 AUTHOR

Jason R Dobson,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

=head2 Moose Declarations

This section contains the object orientted contructors.

=cut

has chromosome	=>	(
	is			=>	'rw',
	isa			=>	'Str',
);

has start	=>	(
	is			=>	'rw',
	isa			=>	'Int',
);

has stop	=>	(
	is			=>	'rw',
	isa			=>	'Int',
);

has genome	=>	(
	is			=>	'rw',
	isa			=>	'Str',
);

has twoBitToFa_executable	=>	(
	is			=>	'ro',
	isa			=>	'Str',
	default		=>	sub {
		my $self = shift;
		my $twoBit_path = `which twoBitToFa`;
		chomp ($twoBit_path);
		return $twoBit_path;
	},
	required	=>	1,
);

=head2 create_temp_fasta

This subroutine creates a temporary Fasta file based on the desired
product size. This subroutine then determines whether relative locations need to be
returned if the primer design type is either for a motif or a summit.

=cut

sub create_temp_fasta {
	my $self = shift;
	my $genomic_dna_start = $self->start;
	my $genomic_dna_stop = $self->stop;
	# Get the twoBitToFa executable and create the temporary Fasta file
	my $twoBitToFa_executable = $self->twoBitToFa_executable;
	my $genome = 'root/static/files/' . $self->genome . '.2bit';
	my $out_file = 'tmp/fasta/temp.fa';
	my $call_string = $genome . ':' . $self->chromosome . ':' . $genomic_dna_start . '-' . $genomic_dna_stop;
	`$twoBitToFa_executable $call_string $out_file`;
}

__PACKAGE__->meta->make_immutable;

1;
