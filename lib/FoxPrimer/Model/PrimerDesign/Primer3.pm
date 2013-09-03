package FoxPrimer::Model::PrimerDesign::Primer3;
use Moose;
use Moose::Util::TypeConstraints;
use Carp;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Stone;
use Boulder::Stream;
use IPC::Run3;
use File::Which;
use File::Temp;
use namespace::autoclean;

=head1 NAME

FoxPrimer::Model::PrimerDesign::Primer3

=cut

=head1 AUTHOR

Jason R. Dobson, L<foxprimer@gmail.com>

=cut

=head1 DESCRIPTION

This module provides an interface between Perl and the primer3 command-line
executable 'primer3_core' for the design of qPCR primers.

This version supports primer3-2.3.5. Please check the Primer3 manual for
specific changes to the primer design options.

=cut

=head1 SYNOPSIS

TODO

=cut

=head2 primer3_path

This Moose attribute holds the path to the primer3_core executable. This
attribute is dynamically defined and can not be set by the user.

=cut

has primer3_path    =>  (
    is          =>  'ro',
    isa         =>  'Str',
    predicate   =>  'has_primer3_path',
    writer      =>  '_set_primer3_path',
);

before  'primer3_path'  =>  sub {
    my $self = shift;
    unless($self->has_primer3_path) {
        $self->_set_primer3_path($self->_get_primer3_path);
    }
};

=head2 _get_primer3_path

This private subroutine is run dynamically to get the path to the 'primer3_core'
executable. If the executable is not found, the module will cease execution of
the program.

=cut

sub _get_primer3_path   {
    my $self = shift;

    # Get the primer3_core path
    my $primer3_path = which('primer3_core');
    ($primer3_path && -x $primer3_path) ? return $primer3_path : croak
    "\n\nCould not find the path to Primer3 [primer3_core].\n\n";
}

=head2 Input Tags

The following Moose attributes are used as input parameters for 'primer3_core'.
Attributes that are in all capital letters are the attribute values that will be
directly fed into primer3. Lowercase attributes are optional and can be used to
construct the input parameters needed for primer3 input.

=cut

=head2 SEQUENCE_ID

This Moose attribute holds a string description for the primers to be designed.
This is an optional value.

=cut

has SEQUENCE_ID =>  (
    is          =>  'ro',
    isa         =>  'Str',
);

=head2 SEQUENCE_TEMPLATE

This Moose attribute holds a nucleotide string [5'->3']. The string should
appear on only one line in the Boulder::Stream object. Lowercase letters are
masked.

=cut

has SEQUENCE_TEMPLATE   =>  (
    is          =>  'ro',
    isa         =>  'Str',
    required    =>  1,
    lazy        =>  1,
    default     =>  sub {
        croak "\n\nA sequence template must be defined to use this module.\n\n";
    },
);

=head2 seq_inc_start

This Moose attribute holds an Array Ref of index values of the starting position
of subsequences in the SEQUENCE_TEMPLATE to be used for primer design.

=cut

has seq_inc_start   =>  (
    is          =>  'ro',
    isa         =>  'ArrayRef[Int]',
    predicate   =>  'has_seq_inc_start',
);

=head2 seq_inc_length

This Moose attribute holds an Array Ref of the length of each subsequence of
SEQUENCE_TEMPLATE to be included for primer design.

=cut

has seq_inc_length  =>  (
    is          =>  'ro',
    isa         =>  'ArrayRef[Int]',
    predicate   =>  'has_seq_inc_length',
);

=head2 SEQUENCE_TARGET

This Moose attribute holds the string that is passed to Primer3 that optionally
defines the subsequence of SEQUENCE_TEMPLATE to be used for primer design. This
attribute can be defined in two ways: 1) by setting the valid primer3 string at
object creation as a space-separated list: <START>,<LENGTH> or 2) by setting
seq_inc_start and seq_inc_length and letting the module define the string
automatically.

=cut

has SEQUENCE_TARGET =>  (
    is          =>  'ro',
    isa         =>  'Str',
    predicate   =>  'has_SEQUENCE_TARGET',
    writer      =>  'set_SEQUENCE_TARGET',
);

before  'SEQUENCE_TARGET'   =>  sub {
    my $self = shift;
    unless ( $self->has_SEQUENCE_TARGET ) {
        if ( $self->has_seq_inc_start && $self->has_seq_inc_length ) {
            $self->set_SEQUENCE_TARGET($self->_define_seq_target_string);
        } else {
            $self->set_SEQUENCE_TARGET('');
        }
    }
};

=head2 _define_seq_target_string

This private subroutine is run dynamically to defined SEQUENCE_TARGET when the
user has set seq_inc_start and seq_inc_length.

=cut

sub _define_seq_target_string   {
    my $self = shift;

    # Define a string to hold the sequence target string
    my $seq_target_string = '';

    # Pre-declare an Array Ref to hold the individual sequence targets
    my $seq_targets = [];

    # Iterate through the target subsequence parameters and add them to the
    # Array Ref of sequence targets
    for ( my $i = 0; $i < @{$self->seq_inc_start}; $i++ ) {
        push(@{$seq_targets},
            join(",", $self->seq_inc_start->[$i], $self->seq_inc_length->[$i])
        );
    }

    # Add the targets to the seq_target_string
    if ( $seq_targets && ( scalar ( @{$seq_targets} ) >= 1 ) ) {
        $seq_target_string = join(" ", @{$seq_targets});
    }

    return $seq_target_string;
}

=head2 SEQUENCE_EXCLUDED_REGION

This primer3 parameter is not currently implemented in this module.

=cut

=head2 SEQUENCE_PRIMER_PAIR_OK_REGION_LIST

This primer3 parameter is not currently implemented in this module.

=cut

=head2 SEQUENCE_OVERLAP_JUNCTION_LIST

This primer3 parameter is not currently implemented in this module.

=cut

=head2 SEQUENCE_INTERNAL_EXCLUDED_REGION

This primer3 parameter is not currently implemented in this module.

=cut

=head2 SEQUENCE_PRIMER

The sequence of the left primer to check. Must be a substring of
SEQUENCE_TEMPLATE.

=cut

has SEQUENCE_PRIMER =>  (
    is          =>  'ro',
    isa         =>  'Str',
    required    =>  1,
    lazy        =>  1,
    default     =>  sub {
        croak "\n\nYou must specify the sequence of the left primer to check" . 
        " primers.\n\n";
    },
);

=head2 SEQUENCE_INTERNAL_OLIGO

This primer3 parameter is not currently implemented in this module.

=cut

=head2 SEQUENCE_PRIMER_REVCOMP

This Moose attribute holds the string for the right primer to check. This
sequence must be a substring of the reverse compliment of SEQUENCE_TEMPLATE.

=cut

has SEQUENCE_PRIMER_REVCOMP =>  (
    is          =>  'ro',
    isa         =>  'Str',
    required    =>  1,
    lazy        =>  1,
    default     =>  sub {
        croak "\n\nYou must specify the sequence of the right primer to check" . 
        " primers.\n\n";
    },
);

=head2 SEQUENCE_START_CODON_POSITION

This primer3 parameter is not currently implemented in this module.

=cut

=head2 SEQUENCE_QUALITY

This primer3 parameter is not currently implemented in this module.

=cut

=head2 SEQUENCE_FORCE_LEFT_START

This primer3 parameter is not currently implemented in this module.

=cut

=head2 SEQUENCE_FORCE_LEFT_END

This primer3 parameter is not currently implemented in this module.

=cut

=head2 SEQUENCE_FORCE_RIGHT_START

This primer3 parameter is not currently implemented in this module.

=cut

=head2 SEQUENCE_FORCE_RIGHT_END

This primer3 parameter is not currently implemented in this module.

=cut

=head2 Global Input Tags

The following Moose attributes are the "global" parameters defined for primer3.

=cut

=head2 PRIMER_TASK

This Moose attribute is a string that defines the task to be accomplished by
primer3.

=cut

has PRIMER_TASK =>  (
    is          =>  'ro',
    isa         =>  enum([qw[
            generic
            check_primers
            pick_primer_list
            pick_sequencing_primers
            pick_cloning_primers
            pick_discriminative_primers
            ]
        ]
    ),
    required    =>  1,
    lazy        =>  1,
    default     =>  sub {
        croak "\n\nYou must define a task for primer3 to run this module.\n\n";
    },
);

=head2 PRIMER_PICK_LEFT_PRIMER

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_PICK_INTERNAL_OLIGO

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_PICK_RIGHT_PRIMER

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_NUM_RETURN

This Moose attribute holds the maximum number of primers to return. By default
this value is set to 500.

=cut

has PRIMER_NUM_RETURN   =>  (
    is          =>  'ro',
    isa         =>  'Int',
    required    =>  1,
    default     =>  500,
);

=head2 PRIMER_MIN_3_PRIME_OVERLAP_OF_JUNCTION

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_MIN_5_PRIME_OVERLAP_OF_JUNCTION

This primer3 parameter is not currently implemented in this module.

=cut

=head2 min_product_size

This Moose attribute holds the integer value for the minimum product size
allowed for primer pairs.

=cut

has min_product_size    =>  (
    is          =>  'ro',
    isa         =>  'Int',
    predicate   =>  'has_min_product_size',
);

=head2 max_product_size

This Moose attribute holds the integer value for the maximum size of the
products produced by designed primers.

=cut

has max_product_size    =>  (
    is          =>  'ro',
    isa         =>  'Int',
    predicate   =>  'has_max_product_size',
);

=head2 PRIMER_PRODUCT_SIZE_RANGE

This Moose attribute holds the string for the product size range allowed for
primer design. This string must be set at object creation. By default it is set
to '70-150'. Optionally, it can be manually set when the object is created, or
if the user has set min_product_size and max_product_size the string can be set
dynamically.

=cut

has PRIMER_PRODUCT_SIZE_RANGE   =>  (
    is          =>  'ro',
    isa         =>  'Str',
    predicate   =>  'has_PRIMER_PRODUCT_SIZE_RANGE',
    writer      =>  'set_PRIMER_PRODUCT_SIZE_RANGE',
);

before  'PRIMER_PRODUCT_SIZE_RANGE' =>  sub {
    my $self = shift;
    unless ($self->has_PRIMER_PRODUCT_SIZE_RANGE) {
        if ( $self->has_min_product_size && $self->has_max_product_size ) {
            $self->set_PRIMER_PRODUCT_SIZE_RANGE($self->_define_primer_product_size_range);
        } else {
            $self->set_PRIMER_PRODUCT_SIZE_RANGE('70-150');
        }
    }
};

=head2 _define_primer_product_size_range

This private subroutine is dynamically run to define the primer product size
range.

=cut

sub _define_primer_product_size_range   {
    my $self = shift;
    if ( $self->min_product_size < $self->max_product_size ) {
        return join('-', $self->min_product_size, $self->max_product_size);
    } else {
        croak "\n\nThe product size range values you have defined are not" .
        " valid. The max_product_size must be larger than the min_product_size"
        . ".\n\n";
    }
}

=head2 PRIMER_PRODUCT_OPT_SIZE

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_PAIR_WT_PRODUCT_SIZE_LT

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_PAIR_WT_PRODUCT_SIZE_GT

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_MIN_SIZE

This Moose attribute holds the integer value for the minimum size of a primer.
By default, this value is set to 18.

=cut

has PRIMER_MIN_SIZE =>  (
    is          =>  'ro',
    isa         =>  'Int',
    default     =>  18,
    required    =>  1,
);

=head2 PRIMER_INTERNAL_MIN_SIZE

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_OPT_SIZE

This Moose attribute holds the integer value for the optimal size of primers to
be designed. By default this value is set to 20.

=cut

has PRIMER_OPT_SIZE =>  (
    is          =>  'ro',
    isa         =>  'Int',
    default     =>  20,
    required    =>  1,
);

=head2 PRIMER_INTERNAL_OPT_SIZE

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_MAX_SIZE

This Moose attribute holds the integer value for the maximum size of a primer to
be designed. By default, this attribute is set to 24.

=cut

has PRIMER_MAX_SIZE =>  (
    is          =>  'ro',
    isa         =>  'Int',
    default     =>  24,
    required    =>  1,
);

=head2 PRIMER_INTERNAL_MAX_SIZE

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_WT_SIZE_LT

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_WT_SIZE_LT

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_WT_SIZE_GT

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_WT_SIZE_GT

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_MIN_GC

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_MIN_GC

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_OPT_GC_PERCENT

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_OPT_GC_PERCENT

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_MAX_GC

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_MAX_GC

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_WT_GC_PERCENT_LT

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_WT_GC_PERCENT_LT

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_WT_GC_PERCENT_GT

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_WT_GC_PERCENT_GT

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_GC_CLAMP

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_MAX_END_GC

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_MIN_TM

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_MIN_TM

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_OPT_TM

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_OPT_TM

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_MAX_TM

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_MAX_TM

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_PAIR_MAX_DIFF_TM

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_WT_TM_LT

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_WT_TM_LT

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_WT_TM_GT

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_WT_TM_GT

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_PAIR_WT_DIFF_TM

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_PRODUCT_MIN_TM

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_PRODUCT_OPT_TM

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_PRODUCT_MAX_TM

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_PAIR_WT_PRODUCT_TM_LT

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_PAIR_WT_PRODUCT_TM_GT

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_TM_FORMULA

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_SALT_MONOVALENT

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_SALT_MONOVALENT

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_SALT_DIVALENT

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_SALT_DIVALENT

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_DNTP_CONC

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_DNTP_CONC

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_SALT_CORRECTIONS

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_DNA_CONC

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_DNA_CONC

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_THERMODYNAMIC_OLIGO_ALIGNMENT

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_THERMODYNAMIC_TEMPLATE_ALIGNMENT

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_THERMODYNAMIC_PARAMETERS_PATH

This Moose attribute holds the path to the primer3_config directory. This
attribute is required and must be set at object creation.

=cut

has PRIMER_THERMODYNAMIC_PARAMETERS_PATH    =>  (
    is          =>  'ro',
    isa         =>  'Str',
    required    =>  1,
    lazy        =>  1,
    default     =>  sub {
        croak "\n\nYou must define the path to the primer3_config " .
        "directory.\n\n";
    },
);

=head2 PRIMER_MAX_SELF_ANY

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_MAX_SELF_ANY_TH

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_MAX_SELF_ANY

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_MAX_SELF_ANY_TH

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_PAIR_MAX_COMPL_ANY

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_PAIR_MAX_COMPL_ANY_TH

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_WT_SELF_ANY

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_WT_SELF_ANY_TH

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_WT_SELF_ANY

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_WT_SELF_ANY_TH

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_PAIR_WT_COMPL_ANY

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_PAIR_WT_COMPL_ANY_TH

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_MAX_SELF_END

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_MAX_SELF_END_TH

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_MAX_SELF_END

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_MAX_SELF_END_TH

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_PAIR_MAX_COMPL_END

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_PAIR_MAX_COMPL_END_TH

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_WT_SELF_END

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_WT_SELF_END_TH

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_WT_SELF_END

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_WT_SELF_END_TH

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_PAIR_WT_COMPL_END

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_PAIR_WT_COMPL_END_TH

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_MAX_HAIRPIN_TH

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_MAX_HAIRPIN_TH

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_WT_HAIRPIN_TH

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_WT_HAIRPIN_TH

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_MAX_END_STABILITY

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_WT_END_STABILITY

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_MAX_NS_ACCEPTED

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_MAX_NS_ACCEPTED

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_WT_NUM_NS

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_WT_NUM_NS

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_MAX_POLY_X

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_MAX_POLY_X

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_MIN_LEFT_THREE_PRIME_DISTANCE

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_MIN_RIGHT_THREE_PRIME_DISTANCE

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_MIN_THREE_PRIME_DISTANCE

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_PICK_ANYWAY

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_LOWERCASE_MASKING

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_EXPLAIN_FLAG

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_LIBERAL_BASE

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_FIRST_BASE_INDEX

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_MAX_TEMPLATE_MISPRIMING

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_MAX_TEMPLATE_MISPRIMING_TH

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_PAIR_MAX_TEMPLATE_MISPRIMING

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_PAIR_MAX_TEMPLATE_MISPRIMING_TH

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_WT_TEMPLATE_MISPRIMING

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_WT_TEMPLATE_MISPRIMING_TH

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_PAIR_WT_TEMPLATE_MISPRIMING

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_PAIR_WT_TEMPLATE_MISPRIMING_TH

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_MISPRIMING_LIBRARY

This Moose attribute holds the path to the mispriming library file. This value
must be set at object creation time.

=cut

has PRIMER_MISPRIMING_LIBRARY   =>  (
    is          =>  'ro',
    isa         =>  'Str',
    required    =>  1,
    lazy        =>  1,
    default     =>  sub {
        croak "\n\nYou must define the path to the mispriming file.\n\n";
    },
);

=head2 PRIMER_INTERNAL_MISHYB_LIBRARY

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_LIB_AMBIGUITY_CODES_CONSENSUS

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_MAX_LIBRARY_MISPRIMING

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_MAX_LIBRARY_MISHYB

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_PAIR_MAX_LIBRARY_MISPRIMING

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_WT_LIBRARY_MISPRIMING

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_WT_LIBRARY_MISHYB

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_PAIR_WT_LIBRARY_MISPRIMING

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_MIN_QUALITY

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_MIN_QUALITY

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_MIN_END_QUALITY

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_QUALITY_RANGE_MIN

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_QUALITY_RANGE_MAX

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_WT_SEQ_QUAL

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_WT_SEQ_QUAL

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_PAIR_WT_PR_PENALTY

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_PAIR_WT_IO_PENALTY

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INSIDE_PENALTY

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_OUTSIDE_PENALTY

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_WT_POS_PENALTY

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_SEQUENCING_LEAD

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_SEQUENCING_SPACING

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_SEQUENCING_INTERVAL

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_SEQUENCING_ACCURACY

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_WT_END_QUAL

This primer3 parameter is not currently implemented in this module.

=cut

=head2 PRIMER_INTERNAL_WT_END_QUAL

This primer3 parameter is not currently implemented in this module.

=cut

=head2 creation_stone

This Moose attribute is dynamically defined to hold a Stone data object that
will be used for the creation of primer3 primers.

=cut

has creation_stone  =>  (
    is          =>  'ro',
    isa         =>  'Stone',
    predicate   =>  'has_creation_stone',
    writer      =>  '_set_creation_stone',
);

before  'creation_stone'    =>  sub {
    my $self = shift;
    unless ($self->has_creation_stone) {
        $self->_set_creation_stone($self->_define_creation_stone);
    }
};

=head2 _define_creation_stone

This private subroutine is run to create a Stone data structure of the
information needed to make primers for primer3.

=cut

sub _define_creation_stone   {
    my $self = shift;

    # Create the Stone object
    my $stone = new Stone(
        SEQUENCE_ID         =>  $self->SEQUENCE_ID,
        SEQUENCE_TEMPLATE   =>  $self->SEQUENCE_TEMPLATE,
        SEQUENCE_TARGET     =>  $self->SEQUENCE_TARGET,
        PRIMER_TASK         =>  $self->PRIMER_TASK,
        PRIMER_NUM_RETURN   =>  $self->PRIMER_NUM_RETURN,
        PRIMER_PRODUCT_SIZE_RANGE   =>  $self->PRIMER_PRODUCT_SIZE_RANGE,
        PRIMER_MIN_SIZE     =>  $self->PRIMER_MIN_SIZE,
        PRIMER_OPT_SIZE     =>  $self->PRIMER_OPT_SIZE,
        PRIMER_MAX_SIZE     =>  $self->PRIMER_MAX_SIZE,
        PRIMER_THERMODYNAMIC_PARAMETERS_PATH    =>  $self->PRIMER_THERMODYNAMIC_PARAMETERS_PATH,
        PRIMER_MISPRIMING_LIBRARY   =>  $self->PRIMER_MISPRIMING_LIBRARY,
    );

    return $stone;
}

=head2 input_stream

This Moose attribute holds a Boulder::Stream object that writes the primer3
input parameters to STDOUT.

=cut

has input_stream    =>  (
    is          =>  'ro',
    isa         =>  'Boulder::Stream',
    predicate   =>  'has_input_stream',
    writer      =>  '_set_input_stream',
);

before  'input_stream'  =>  sub {
    my $self = shift;
    unless($self->has_input_stream) {
        $self->_set_input_stream($self->_define_input_stream);
    }
};

=head2 _define_input_stream

This private subroutine is dynamically defined to create a Boulder::Stream
object to write the Stone object of data for primer3.

=cut

sub _define_input_stream    {
    my $self = shift;
    return Boulder::Stream->new(
        -out    =>  File::Temp->new(),
    );
}

=head2 primer_creation_input_file

This Moose attribute is dynamically defined to hold the path to the temporary
file that contains the Boulder::IO data for creating primers.

=cut

has primer_creation_input_file  =>  (
    is          =>  'ro',
    isa         =>  'Str',
    predicate   =>  'has_primer_creation_input_file',
    writer      =>  '_set_primer_creation_input_file'
);

before  'primer_creation_input_file'    =>  sub {
    my $self = shift;
    unless ($self->has_primer_creation_input_file) {
        $self->_set_primer_creation_input_file($self->_define_primer_creation_input_file);
    }
};

=head2 _define_primer_creation_input_file

This private subroutine is dynamically run to return a string to the path of the
temporary file that holds the data for creating primers with primer3.

=cut

sub _define_primer_creation_input_file  {
    my $self = shift;


    # Touch creation_stone and input_stream as methods to make sure they are
    # defined
    $self->creation_stone;
    $self->input_stream;

    if ( $self->has_creation_stone && $self->has_input_stream ) {
        $self->input_stream->put($self->creation_stone);
        return $self->input_stream->{OUT}->filename;
    } else {
        croak "\n\nThere was a problem defining the input stream and the " .
        "stone for creating primers with primer3.\n\n";
    }
}

=head2 primer3_temp_results

This Moose attribute holds a File::Temp object where the results of the primer3
call will be written.

=cut

has 'primer3_temp_results'  =>  (
    is          =>  'ro',
    isa         =>  'Str',
    predicate   =>  'has_primer3_temp_results',
    writer      =>  '_set_primer3_temp_results',
);

before  'primer3_temp_results'  =>  sub {
    my $self = shift;
    unless ($self->has_primer3_temp_results) {
        $self->_set_primer3_temp_results($self->_define_primer3_temp_results);
    }
};

=head2 _define_primer3_temp_results

This private subroutine is dynamically defined to return a file handle from a
File::Temp object.

=cut

sub _define_primer3_temp_results    {
    my $self = shift;
    
    # Define a File::Temp object
    my $tempfile = File::Temp->new();

    return $tempfile->filename;
}

=head2 results_stream

This Moose attribute holds a Boulder::Stream object that will be used to capture
the primer3 results.

=cut

has results_stream    =>  (
    is          =>  'ro',
    isa         =>  'GlobRef',
    predicate   =>  'has_results_stream',
    writer      =>  '_set_results_stream',
);

before  'results_stream'  =>  sub {
    my $self = shift;
    unless($self->has_results_stream) {
        $self->_set_results_stream($self->_define_results_stream);
    }
};

=head2 _define_results_stream

This private subroutine is dynamically defined to create a Boulder::Stream
object to capture the Stone object of results from primer3.

=cut

sub _define_results_stream    {
    my $self = shift;
    return Boulder::Stream->newFh(
        -in =>  $self->primer3_temp_results,
    );
}

=head2 creation_results_stone

This Moose attribute holds a Stone object that contains the results of the
current primer3 run. This attribute is dynamically defined.

=cut

has creation_results_stone  =>  (
    is          =>  'ro',
    isa         =>  'Stone',
    predicate   =>  'has_creation_results_stone',
    writer      =>  '_set_creation_results_stone',
);

before  'creation_results_stone'    =>  sub {
    my $self = shift;
    unless($self->has_creation_results_stone) {
        $self->_set_creation_results_stone($self->make_primers);
    }
};

=head2 make_primers

This subroutine takes the data input by the user, and creates a configuration
file for Primer3. Then, this subroutine runs primer3 and returns a
Boulder::Stream object of primer results.

=cut

sub make_primers    {
    my $self = shift;

    # Create a command to be run by IPC::Run3
    my $cmd = join(
        ' < ', 
        $self->primer3_path,
        $self->primer_creation_input_file
    );

    # Run the command and send the results from STDOUT to the
    # primer3_temp_results file
    run3 $cmd, undef, $self->primer3_temp_results, undef;

    # Return the results as a Stone object
    my $results_stream = $self->results_stream;
    my $results = <$results_stream>;
    return $results;
}

__PACKAGE__->meta->make_immutable;

1;
