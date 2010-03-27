package Locale::CLDR::LDML::Alias;

use strict;
use warnings;
use namespace::autoclean;

use Locale::CLDR::Types qw( Str );

use Moose;

has id => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has method => => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

1;
