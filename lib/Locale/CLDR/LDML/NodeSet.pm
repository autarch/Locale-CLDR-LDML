package Locale::CLDR::LDML::NodeSet;

use strict;
use warnings;
use namespace::autoclean;

use Locale::CLDR::Types qw( ArrayRef NodesForNodeSet Str );

use Moose;

has _nodes => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => NodesForNodeSet,
    required => 1,
    init_arg => 'nodes',
    handles  => { nodes => 'elements' },
);

has best_node => (
    is       => 'ro',
    isa      => 'Locale::CLDR::LDML::Node',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_best_node',
);

sub BUILDARGS {
    my $self = shift;

    my $args = $self->SUPER::BUILDARGS(@_);

    return $args
        unless $args->{nodes}
            && ( ref $args->{nodes} || q{} ) eq 'ARRAY';

    $args->{nodes} = [
        sort {
                   $a->draft_level() <=> $b->draft_level()
                or ( $a->alt_value() || q{} ) cmp( $b->alt_value() || q{} )
                or $a->value() cmp $b->value()
            } @{ $args->{nodes} }
    ];

    return $args;
}

sub _build_best_node {
    my $self = shift;

    return ( $self->nodes() )[0];
}

1;
