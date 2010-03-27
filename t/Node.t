use strict;
use warnings;

use Test::Exception;
use Test::More;

use Locale::CLDR::LDML::Node;

{
    my $node = Locale::CLDR::LDML::Node->new(
        value        => 42,
        draft_status => undef,
        alt_value    => undef,
    );

    ok( !$node->is_draft(), 'node is_draft is false' );

    is( $node->draft_level(), 0, 'draft level is 0' );
}

{
    throws_ok {
        Locale::CLDR::LDML::Node->new(
            value        => 42,
            draft_status => 'foo',
            alt_value    => undef,
        );
    }
    qr/draft_status.+type constraint/, 'cannot have a draft status of foo';
}

{
    my $node = Locale::CLDR::LDML::Node->new(
        value        => 42,
        draft_status => 'approved',
        alt_value    => undef,
    );

    ok( $node->is_draft(), 'node is_draft is true' );

    is( $node->draft_level(), 1, 'draft level is 1' );
}

done_testing();
