use strict;
use warnings;

use Test::Exception;
use Test::More;

use Locale::CLDR::LDML::Node;
use Locale::CLDR::LDML::NodeSet;

{
    my @nodes = nodes(
        {
            value        => 42,
            draft_status => undef,
            alt_value    => undef,
        }
    );

    my $set = Locale::CLDR::LDML::NodeSet->new( nodes => \@nodes );

    is(
        $set->best_node(), $nodes[0],
        'best_node returns only node'
    );
}

{
    my @nodes = nodes(
        {
            value        => 44,
            draft_status => 'contributed',
            alt_value    => undef,
        }, {
            value        => 42,
            draft_status => undef,
            alt_value    => undef,
        }
    );

    my $set = Locale::CLDR::LDML::NodeSet->new( nodes => \@nodes );

    is(
        $set->best_node(), $nodes[1],
        'best_node returns non draft node'
    );
}

{
    my @nodes = nodes(
        {
            value        => 44,
            draft_status => 'contributed',
            alt_value    => undef,
        }, {
            value        => 47,
            draft_status => 'approved',
            alt_value    => undef,
        }
    );

    my $set = Locale::CLDR::LDML::NodeSet->new( nodes => \@nodes );

    is(
        $set->best_node(), $nodes[1],
        'best_node sorts on draft status (both are drafts)'
    );
}

{
    my @nodes = nodes(
        {
            value        => 44,
            draft_status => 'contributed',
            alt_value    => 'y',
        }, {
            value        => 47,
            draft_status => 'contributed',
            alt_value    => 'x',
        }
    );

    my $set = Locale::CLDR::LDML::NodeSet->new( nodes => \@nodes );

    is(
        $set->best_node(), $nodes[1],
        'best_node sorts on alt_value if needed'
    );
}

{
    my @nodes = nodes(
        {
            value        => 47,
            draft_status => 'contributed',
            alt_value    => 'y',
        }, {
            value        => 44,
            draft_status => 'contributed',
            alt_value    => 'y',
        }
    );

    my $set = Locale::CLDR::LDML::NodeSet->new( nodes => \@nodes );

    is(
        $set->best_node(), $nodes[1],
        'best_node sorts on value if needed'
    );
}

{
    my @nodes = nodes(
        {
            value        => 44,
            draft_status => undef,
            alt_value    => undef,
        }, {
            value        => 47,
            draft_status => undef,
            alt_value    => undef,
        }
    );

    throws_ok { Locale::CLDR::LDML::NodeSet->new( nodes => \@nodes ) }
    qr/more than one non-draft node/,
        'cannot have two non-draft nodes in a node set';
}

sub nodes {
    return map { Locale::CLDR::LDML::Node->new( %{$_} ) } @_;
}

done_testing();
