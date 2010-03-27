package Locale::CLDR::LDML::Node;

use strict;
use warnings;
use namespace::autoclean;

use Locale::CLDR::Types qw( Bool DraftStatus Int Maybe Str );

use Moose;

has value => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has draft_status => (
    is       => 'ro',
    isa      => Maybe [DraftStatus],
    required => 1,
);

has is_draft => (
    is       => 'ro',
    isa      => Bool,
    init_arg => undef,
    lazy     => 1,
    default  => sub { defined $_[0]->draft_status() },
);

{
    my %draft_levels = (
        q{}         => 0,
        approved    => 1,
        contributed => 2,
        provisional => 3,
        unconfirmed => 4,
    );

    has draft_level => (
        is       => 'ro',
        isa      => Int,
        init_arg => undef,
        lazy     => 1,
        default  => sub { $draft_levels{ $_[0]->draft_status() || q{} } },
    );
}

has alt_value => (
    is       => 'ro',
    isa      => Maybe [Str],
    required => 1,
);


1;
