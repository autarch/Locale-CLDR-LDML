package Locale::CLDR::Types::Internal;

use strict;
use warnings;

use MooseX::Types -declare => [
    qw( NodesForNodeSet
        DraftStatus
        HashRefOfNodeSetsOrAlias
        NodeSetOrAlias
        _Alias
        _NodeSet
        _HofN
        )
];

use MooseX::Types::Moose qw( ArrayRef HashRef Str );

subtype DraftStatus,
    as Str,
    where {/^(?:approved|contributed|provisional|unconfirmed)$/};

subtype NodesForNodeSet,
    as ArrayRef [ class_type 'Locale::CLDR::LDML::Node' ],
    where {
        @{$_} > 0 && ( scalar grep { !$_->is_draft() } @{$_} ) <= 1;
    },
    message {
        'Must have at least one node in a node set, and cannot have more than one non-draft node'
    };

subtype _Alias, as class_type 'Locale::CLDR::LDML::Alias';
subtype _NodeSet, as class_type 'Locale::CLDR::LDML::NodeSet';
subtype _HofN, as HashRef [_NodeSet];

subtype HashRefOfNodeSetsOrAlias,
    as _HofN | _Alias;

subtype NodeSetOrAlias, as _NodeSet | _Alias;

1;

