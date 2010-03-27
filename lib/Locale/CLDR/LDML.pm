package Locale::CLDR::LDML;

use strict;
use warnings;
use utf8;
use namespace::autoclean;

use Carp ();
use File::Basename qw( dirname );
use FindBin;
use Lingua::EN::Inflect qw( PL_N );
use List::AllUtils qw( all first );
use Locale::CLDR::LDML::Alias;
use Locale::CLDR::LDML::Node;
use Locale::CLDR::LDML::NodeSet;
use Locale::CLDR::Types
    qw( Dir File HashRef HashRefOfNodeSetsOrAlias Int Maybe NodeSetOrAlias Str );
use Path::Class;
use Storable qw( nstore_fd fd_retrieve );
use XML::LibXML qw( :libxml );

use Moose;
use MooseX::ClassAttribute;
use Moose::Util::TypeConstraints qw( class_type );

class_has '_RootDir' => (
    is      => 'ro',
    isa     => Dir,
    builder => '_BuildRootDir',
);

my $GregorianRoot = q{//dates/calendars/calendar[@type='gregorian']};

class_has _XPathAttributeMap => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => HashRef [Str],
    default => sub { {} },
    handles => {
        __AddAttributeForXPath => 'set',
        _AttributeForXPath     => 'get',
    },
);

has id => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has source_file => (
    is       => 'ro',
    isa      => File,
    required => 1,
);

has document => (
    is       => 'ro',
    isa      => ( class_type 'XML::LibXML::Document' ),
    required => 1,
);

has version => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    builder => '_build_version',
);

has generation_date => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    builder => '_build_generation_date',
);

has language => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub { ( $_[0]->_parse_id() )[0] },
);

has script => (
    is      => 'ro',
    isa     => Maybe [Str],
    lazy    => 1,
    default => sub { ( $_[0]->_parse_id() )[1] },
);

has territory => (
    is      => 'ro',
    isa     => Maybe [Str],
    lazy    => 1,
    default => sub { ( $_[0]->_parse_id() )[2] },
);

has variant => (
    is      => 'ro',
    isa     => Maybe [Str],
    lazy    => 1,
    default => sub { ( $_[0]->_parse_id() )[3] },
);

has alias_to => (
    is      => 'ro',
    isa     => Maybe [Str],
    lazy    => 1,
    builder => '_build_alias_to',
);

has parent_id => (
    is      => 'ro',
    isa     => Maybe [Str],
    lazy    => 1,
    builder => '_build_parent_id',
);

has fallback => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    builder => '_build_fallback',
);

for my $name (qw( day month quarter )) {
    for my $context (qw( format stand_alone )) {
        for my $size (qw( wide abbreviated narrow )) {

            my $attr = join q{_}, $name, $context, $size;

            ( my $xpath_context = $context ) =~ s/_/-/g;

            __PACKAGE__->_make_nodeset_hash_attr(
                attr          => $attr,
                xpath_name    => $name,
                xpath_context => $xpath_context,
                xpath_size    => $size,
                xpath_method  => '_day_month_quarter_xpath',
            );
        }
    }
}

# eras have a different name scheme for sizes than other data elements, go
# figure.
for my $size (
    [ wide        => 'Names' ],
    [ abbreviated => 'Abbr' ],
    [ narrow      => 'Narrow' ]
    ) {

    my $attr = 'era_' . $size->[0];

    __PACKAGE__->_make_nodeset_hash_attr(
        attr         => $attr,
        xpath_size   => $size->[1],
        xpath_method => '_era_xpath',
    );
}

for my $length (qw( full long medium short )) {
    for my $type (qw( date time dateTime )) {
        my $attr = lc $type . q{_format_} . $length;

        __PACKAGE__->_make_single_nodeset_attr(
            attr         => $attr,
            xpath_type   => $type,
            xpath_length => $length,
            xpath_method => '_format_xpath',
        );
    }
}

has default_date_format_length => (
    is      => 'ro',
    isa     => Maybe [Str],
    lazy    => 1,
    default => sub {
        $_[0]->_find_one_node_attribute(
            $GregorianRoot . '/dateFormats/default',
            'choice'
        );
    },
);

has default_time_format_length => (
    is      => 'ro',
    isa     => Maybe [Str],
    lazy    => 1,
    default => sub {
        $_[0]->_find_one_node_attribute(
            $GregorianRoot . '/timeFormats/default',
            'choice'
            ),
            ;
    },
);

has default_datetime_format_length => (
    is      => 'ro',
    isa     => Maybe [Str],
    lazy    => 1,
    default => sub {
        $_[0]->_find_one_node_attribute(
            $GregorianRoot . '/dateTimeFormats/default',
            'choice'
            ),
            ;
    },
);

__PACKAGE__->_make_nodeset_hash_attr(
    attr  => 'available_formats',
    xpath => $GregorianRoot
        . '/dateTimeFormats/availableFormats',
    xml_attr => 'id',
);

has default_interval_format => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    builder => '_build_default_interval_format',
);

has interval_formats => (
    is      => 'ro',
    isa     => HashRef [ HashRefOfNodeSetsOrAlias ],
    lazy    => 1,
    builder => '_build_interval_formats',
);

has field_names => (
    is      => 'ro',
    isa     => HashRef [ HashRef['Locale::CLDR::LDML::NodeSet'] ],
    lazy    => 1,
    builder => '_build_field_names',
);

class_has FirstDayOfWeekIndex => (
    is      => 'ro',
    isa     => HashRef [Int],
    lazy    => 1,
    builder => '_BuildFirstDayOfWeekIndex',
);

has first_day_of_week => (
    is      => 'ro',
    isa     => Int,
    lazy    => 1,
    builder => '_build_first_day_of_week',
);

for my $thing (qw( language script territory variant )) {

    {
        my $en_attr         = q{en_} . $thing;
        my $en_builder_name = '_build_' . $en_attr;

        has $en_attr => (
            is      => 'ro',
            isa     => ( $thing eq 'language' ? Str : Maybe [Str] ),
            lazy    => 1,
            builder => $en_builder_name,
        );

        my $en_ldml;
        my $en_builder = sub {
            my $self = shift;

            my $val_from_id = $self->$thing();
            return unless defined $val_from_id;

            $en_ldml
                ||= ( ref $self )
                ->new_from_file(
                $self->source_file()->dir()->file('en.xml') );

            my $xpath
                = 'localeDisplayNames/'
                . PL_N($thing) . q{/}
                . $thing
                . q{[@type='}
                . $self->$thing() . q{']};

            return $en_ldml->_find_one_node_text($xpath);
        };

        __PACKAGE__->meta()->add_method( $en_builder_name => $en_builder );
    }

    {
        my $native_attr         = q{native_} . $thing;
        my $native_builder_name = '_build_' . $native_attr;

        has $native_attr => (
            is      => 'ro',
            isa     => Maybe [Str],
            lazy    => 1,
            builder => $native_builder_name,
        );

        my $native_builder = sub {
            my $self = shift;

            my $val_from_id = $self->$thing();
            return unless defined $val_from_id;

            my $xpath
                = 'localeDisplayNames/'
                . PL_N($thing) . q{/}
                . $thing
                . q{[@type='}
                . $self->$thing() . q{']};

            return $self->_find_one_node_text($xpath);
        };

        __PACKAGE__->meta()
            ->add_method( $native_builder_name => $native_builder );
    }
}

sub _make_nodeset_hash_attr {
    my $class = shift;
    my %def   = @_;

    my $builder_name = '_build_' . $def{attr};

    has $def{attr} => (
        is      => 'ro',
        isa     => HashRefOfNodeSetsOrAlias,
        lazy    => 1,
        builder => $builder_name,
    );

    my $xpath;
    if ( $def{xpath} ) {
        $xpath = $def{xpath};
    }
    else {
        my $xpath_method = $def{xpath_method};
        $xpath = $class->$xpath_method(%def);
    }

    $class->_AddAttributeForXPath( $xpath => $def{attr} );

    my $builder = sub {
        my $self = shift;

        return $self->_make_nodesets_from_xpath(
            $xpath,
            $def{xml_attr} || 'type',
        );
    };

    $class->meta()->add_method( $builder_name => $builder );
}

sub _make_single_nodeset_attr {
    my $class = shift;
    my %def   = @_;

    my $builder_name = '_build_' . $def{attr};

    has $def{attr} => (
        is      => 'ro',
        isa     => NodeSetOrAlias,
        lazy    => 1,
        builder => $builder_name,
    );

    my $xpath;
    if ( $def{xpath} ) {
        $xpath = $def{xpath};
    }
    else {
        my $xpath_method = $def{xpath_method};
        $xpath = $class->$xpath_method(%def);
    }

    $class->_AddAttributeForXPath( $xpath => $def{attr} );

    my $builder = sub {
        my $self = shift;

        return $self->_xml_nodes_as_object(
            [ $self->document()->documentElement()->findnodes($xpath) ],
        );
    };

    $class->meta()->add_method( $builder_name => $builder );
}

sub _day_month_quarter_xpath {
    my $self = shift;
    my %def  = @_;

    my $name = $def{xpath_name};

    return (
        join '/',
        $GregorianRoot,
        PL_N($name),
        $name . 'Context' . q{[@type='} . $def{xpath_context} . q{']},
        $name . 'Width' . q{[@type='} . $def{xpath_size} . q{']}
    );
}

sub _era_xpath {
    my $self = shift;
    my %def  = @_;

    return (
        join '/',
        $GregorianRoot,
        'eras',
        'era' . $def{xpath_size}
    );
}

sub _format_xpath {
    my $self = shift;
    my %def  = @_;

    my $path = (
        join '/',
        $GregorianRoot,
        $def{xpath_type} . 'Formats',
        $def{xpath_type}
            . q{FormatLength[@type='}
            . $def{xpath_length} . q{']},
        $def{xpath_type} . 'Format' . '/pattern'
    );
}

sub _available_formats_xpath {
    return
        $GregorianRoot . '/dateTimeFormats/availableFormats/dateFormatItem';
}

sub _make_nodesets_from_xpath {
    my $self     = shift;
    my $xpath    = shift;
    my $xml_attr = shift;
    my $root_node = shift || $self->document()->documentElement();

    my $parent_list = $root_node->findnodes($xpath);
    if ( $parent_list->size() > 1 ) {
        die "Found more than node for $xpath in " . $self->source_file();
    }
    elsif ( $parent_list->size() == 0 ) {
        return {};
    }

    my $parent   = $parent_list->shift();
    my @children = $parent->nonBlankChildNodes();

    return $self->_make_nodesets_from_nodes( \@children, $xml_attr );
}

sub _make_nodesets_from_nodes {
    my $self     = shift;
    my $nodes    = shift;
    my $xml_attr = shift;

    if ( @{$nodes} == 1 && $nodes->[0]->localname() eq 'alias' ) {
        return $self->_alias_node_as_object( $nodes->[0] );
    }

    my %index;
    for my $xml_node ( @{$nodes} ) {
        push @{ $index{ $xml_node->getAttribute($xml_attr) } }, $xml_node;
    }

    my %sets;
    for my $xml_attr_value ( sort keys %index ) {
        my $set = $self->_xml_nodes_as_object( $index{$xml_attr_value} );

        $sets{$xml_attr_value} = $set;
    }

    return \%sets;
}

sub _alias_node_as_object {
    my $self = shift;
    my $node = shift;

    my $source = $node->getAttribute('source');

    my $id = $source eq 'locale' ? 'self' : $source;
    my $method = $self->_alias_xpath_as_method(
        $node->getAttribute('path'),
        $node,
    );

    return Locale::CLDR::LDML::Alias->new(
        id     => $id,
        method => $method,
    );
}

sub _alias_xpath_as_method {
    my $self  = shift;
    my $xpath = shift;
    my $node  = shift;

    $xpath ||= $node->parentNode()->nodePath();

    if ( $xpath =~ /\.\./ ) {
        my @nodes = $node->parentNode()->findnodes($xpath);

        if ( @nodes > 1 ) {
            die "Alias path $xpath on "
                . $node->nodePath()
                . ' resolved to more than one node.';
        }
        elsif ( @nodes == 0 ) {
            die "Alias path $xpath on "
                . $node->nodePath()
                . ' did not resolve to any node.';
        }

        $xpath = $nodes[0]->nodePath();
    }

    my $attr = $self->_AttributeForXPath($xpath)
        or die "Cannot find an attribute $xpath";

    return $attr;
}

sub _xml_nodes_as_object {
    my $self      = shift;
    my $xml_nodes = shift;

    my @nodes = map { $self->_xml_node_as_object($_) } @{$xml_nodes};

    return Locale::CLDR::LDML::NodeSet->new(
        nodes => \@nodes,
    );
}

sub _xml_node_as_object {
    my $self     = shift;
    my $xml_node = shift;

    unless ( all { $_->nodeType() == XML_TEXT_NODE } $xml_node->childNodes() ) {
        die $xml_node->nodePath() . ' contains non-text child nodes';
    }

    return Locale::CLDR::LDML::Node->new(
        value        => $xml_node->textContent(),
        draft_status => $xml_node->getAttribute('draft'),
        alt_value    => $xml_node->getAttribute('alt'),
    );
}

sub _build_alias_to {
    my $self = shift;

    my $source = $self->_find_one_node_attribute( 'alias', 'source' );
    return $source if defined $source;

    return;
}

sub _build_parent_id {
    my $self = shift;

    return if $self->id() eq 'root';

    my @parts = (
        grep {defined} $self->language(),
        $self->script(),
        $self->territory(),
        $self->variant(),
    );

    pop @parts;

    if (@parts) {
        return join '_', @parts;
    }
    else {
        return 'root';
    }
}

sub _BuildRootDir {
    my $class = shift;

    my @dirs = map { dir( @{$_} ) } (
        # Works for my project dir layout
        [
            dirname( $INC{'Locale/CLDR/LDML.pm'} ),
            '..', '..', '..', '..', 'Locale-CLDR', 'cldr-data'
        ],
        # Works for my project dir layout when running tests
        [ $FindBin::Bin, '..', '..', 'Locale-CLDR', 'cldr-data' ]
    );

    push @dirs, dir( $ENV{CLDR_DATA_DIR} )
        if exists $ENV{CLDR_DATA_DIR};

    for my $dir (@dirs ) {
        return $dir->resolve() if -d $dir;
    }

    my $msg = "Could not find a CLDR data root directory in any of:\n";
    $msg .= "  - $_\n" for @dirs;

    die $msg;
}

{
    my %Cache;

    my $Parser;

    BEGIN {
        $Parser = XML::LibXML->new();
        $Parser->load_catalog('/etc/xml/catalog.xml');
        $Parser->load_ext_dtd(0);
    }

    sub new_from_file {
        my $class = shift;
        my $file  = file(shift);

        my $id = $file->basename();
        $id =~ s/\.xml$//i;

        return $Cache{$id}
            if $Cache{$id};

        my $doc = $Parser->parse_file( $file->stringify() );

        return $Cache{$id} = $class->new(
            id          => $id,
            source_file => $file,
            document    => $doc,
        );
    }

    my $RootDocument;

    sub _RootDocument {
        my $class = shift;

        # XXX - any way to determine this path from some context?
        return $RootDocument if $RootDocument;

        my $file = file( $class->_RootDir(), 'common', 'main', 'root.xml' );

        return $RootDocument = $Parser->parse_file( $file->stringify() );
    }
}

sub new_from_id {
    my $class = shift;
    my $id    = shift;

    return $class->new_from_file( $class->_RootDir()->file( 'common', 'main', $id . '.xml' ) );
}

sub _AddAttributeForXPath {
    my $class = shift;
    my $xpath = shift;
    my $attr  = shift;

    my @nodes = $class->_RootDocument()->documentElement()->findnodes($xpath);

    if ( @nodes > 1 ) {
        die "$xpath on root.xml resolved to more than one node.";
    }
    elsif ( @nodes == 0 ) {
        die "$xpath on root.xml did not resolve to any node.";
    }

    $class->__AddAttributeForXPath( $nodes[0]->nodePath() => $attr );
}

sub BUILD {
    my $self = shift;

    my $meth = q{_} . $self->id() . q{_hack};

    # This gives us a chance to apply bug fixes to the data as needed.
    $self->$meth()
        if $self->can($meth);

    return $self;
}

sub _gaa_hack {
    my $self = shift;
    my $data = shift;

    my $xpath = $GregorianRoot
        . q{/days/dayContext[@type='format']/dayWidth[@type='abbreviated']/day[@type='sun']};

    my $day_text = $self->_find_one_node_text($xpath);

    return unless $day_text eq 'Ho';

    # I am completely making this up, but the data is marked as
    # unconfirmed in the locale file and making something up is
    # preferable to having two days with the same abbreviation

    my $day = $self->_find_one_node($xpath);

    $day->removeChildNodes();
    $day->appendChild( $self->document()->createTextNode('Hog') );
}

sub _ve_hack {
    my $self = shift;
    my $data = shift;

    my $xpath = $GregorianRoot
        . q{/months/monthContext[@type='format']/monthWidth[@type='abbreviated']/month[@type='3']};

    my $day_text = $self->_find_one_node_text($xpath);

    return unless $day_text eq 'Ṱha';

    # Again, making stuff up to avoid non-unique abbreviations

    my $day = $self->_find_one_node($xpath);

    $day->removeChildNodes();
    $day->appendChild( $self->document()->createTextNode('Ṱhf') );
}

sub _build_version {
    my $self = shift;

    my $version
        = $self->_find_one_node_attribute( 'identity/version', 'number' );
    $version =~ s/^\$Revision:\s+//;
    $version =~ s/\s+\$$//;

    return $version;
}

sub _build_generation_date {
    my $self = shift;

    my $date
        = $self->_find_one_node_attribute( 'identity/generation', 'date' );
    $date =~ s/^\$Date:\s+//;
    $date =~ s/\s+\$$//;

    return $date;
}

sub _parse_id {
    my $self = shift;

    return $self->id() =~ /([a-z]+)               # language
                           (?: _([A-Z][a-z]+) )?  # script - Title Case - optional
                           (?: _([A-Z]+) )?       # territory - ALL CAPS - optional
                           (?: _([A-Z]+) )?       # variant - ALL CAPS - optional
                          /x;
}

sub _build_available_formats {
    my $self = shift;

    my @nodes
        = $self->document()->documentElement()
        ->findnodes(
        $GregorianRoot . '/dateTimeFormats/availableFormats/dateFormatItem' );

    my %index;
    for my $node (@nodes) {
        push @{ $index{ $node->getAttribute('id') } }, $node;
    }

    my %formats;
    for my $id ( keys %index ) {
        my $preferred = $self->_find_preferred_node( @{ $index{$id} } )
            or next;

        $formats{$id} = join '', map { $_->data() } $preferred->childNodes();
    }

    return \%formats;
}

sub _build_default_interval_format {
    my $self = shift;

    return $self->_find_one_node_text(
        $GregorianRoot
            . '/dateTimeFormats/intervalFormats/intervalFormatFallback',
    );
}

sub _build_interval_formats {
    my $self = shift;

    my @ifi_nodes
        = $self->document()->documentElement()
        ->findnodes( $GregorianRoot
            . '/dateTimeFormats/intervalFormats/intervalFormatItem' );

    my %index;
    for my $ifi_node (@ifi_nodes) {
        for my $gd_node ( $ifi_node->findnodes('greatestDifference') ) {
            push @{ $index{ $ifi_node->getAttribute('id') }
                    { $gd_node->getAttribute('id') } }, $gd_node;
        }
    }

    my %formats;
    for my $ifi_id ( keys %index ) {
        for my $gd_id ( keys %{ $index{$ifi_id} } ) {
            $formats{$ifi_id}{$gd_id}
                = $self->_xml_nodes_as_object( $index{$ifi_id}{$gd_id} );
        }
    }

    return \%formats;
}

sub _build_field_names {
    my $self = shift;

    my @field_nodes = $self->document()->documentElement()
        ->findnodes( $GregorianRoot . '/fields/field' );

    my %names;
    for my $field_node (@field_nodes) {
        my $key = $field_node->getAttribute('type');
        $names{$key} = $self->_make_nodesets_from_nodes(
            [ $field_node->findnodes('./relative') ],
            'type',
        );

        $names{$key}{name} = $self->_xml_nodes_as_object(
            [ $field_node->findnodes('./displayName') ] );
    }

    return \%names;
}

sub _build_first_day_of_week {
    my $self = shift;

    my $terr = $self->territory();
    return 1 unless defined $terr;

    my $index = $self->FirstDayOfWeekIndex();

    return $index->{$terr} || 1;
}

sub _find_values {
    my $self  = shift;
    my $nodes = shift;
    my $attr  = shift;
    my $order = shift;

    my @nodes = $nodes->get_nodelist();

    return [] unless @nodes;

    my %index;

    for my $node (@nodes) {
        push @{ $index{ $node->getAttribute($attr) } }, $node;
    }

    my @preferred;
    for my $i ( 0 .. $#{$order} ) {

        my $attr = $order->[$i];

        # There may be nothing in the index for incomplete sets (of
        # days, months, etc)
        my @matches = @{ $index{$attr} || [] };

        my $preferred = $self->_find_preferred_node(@matches)
            or next;

        $preferred[$i] = join '', map { $_->data() } $preferred->childNodes();
    }

    return \@preferred;
}

sub _find_preferred_node {
    my $self  = shift;
    my @nodes = @_;

    return unless @nodes;

    return $nodes[0] if @nodes == 1;

    my $non_draft = first { !$_->getAttribute('draft') } @nodes;

    return $non_draft if $non_draft;

    return $nodes[0];
}

sub _find_one_node_text {
    my $self = shift;

    my $node = $self->_find_one_node(@_);

    return unless $node;

    return join '', map { $_->data() } $node->childNodes();
}

sub _find_one_node_attribute {
    my $self = shift;

    # attr name will always be last
    my $attr = pop;

    my $node = $self->_find_one_node(@_);

    return unless $node;

    return $node->getAttribute($attr);
}

sub _find_one_node {
    my $self  = shift;
    my $xpath = shift;

    my @nodes = $self->_find_preferred_node(
        $self->document()->documentElement()->findnodes($xpath) );

    if ( @nodes > 1 ) {
        die "Found multiple nodes for $xpath under $GregorianRoot";
    }

    return $nodes[0];
}

{
    my %days = do {
        my $x = 1;
        map { $_ => $x++ } qw( mon tue wed thu fri sat sun );
    };

    sub _BuildFirstDayOfWeekIndex {
        my $class = shift;

        my $file = $class->_RootDir()
            ->file( 'common', 'supplemental', 'supplementalData.xml' );

        my $doc = XML::LibXML->new()->parse_file( $file->stringify() );

        my @nodes = $doc->findnodes('supplementalData/weekData/firstDay');

        my %index;
        for my $node (@nodes) {
            my $day_num = $days{ $node->getAttribute('day') };

            $index{$_} = $day_num
                for split /\s+/, $node->getAttribute('territories');
        }

        return \%index;
    }
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Parses and understands information from the XML data files in the CLDR project
