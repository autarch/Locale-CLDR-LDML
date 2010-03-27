use strict;
use warnings;
use utf8;

use Path::Class;
use Scalar::Util qw( blessed );

use Test::More;

use Locale::CLDR::LDML;

{
    my $tb = Test::Builder->new();
    binmode $_, ':utf8'
        for map { $tb->$_ } qw( output failure_output todo_output );
}

for my $pair (
    [ 'cop_Arab_EG' => [ qw( cop Arab EG ), undef ] ],
    [ 'hy_AM_REVISED' => [ 'hy', undef, 'AM', 'REVISED' ] ],
    [ 'wo_Latn_SN_REVISED' => [qw( wo Latn SN REVISED )] ],
    ) {

    my $id     = $pair->[0];
    my $expect = $pair->[1];

    my $ldml = Locale::CLDR::LDML->new(
        id          => $id,
        source_file => file($0),
        document    => XML::LibXML::Document->new(),
    );

    is_deeply(
        [ $ldml->_parse_id() ],
        $expect,
        "_parse_id for $id"
    );
}

{
    my $ldml = Locale::CLDR::LDML->new_from_id('zh_MO');

    is( $ldml->alias_to(), 'zh_Hant_MO', 'zh_MO is an alias to zh_Hant_MO' );
}

{
    my $ldml = Locale::CLDR::LDML->new_from_id('root');

    my %day = (
        sun => 1,
        mon => 2,
        tue => 3,
        wed => 4,
        thu => 5,
        fri => 6,
        sat => 7,
    );

    my %month = map { $_ => $_ } 1..12;

    my %quarter_narrow = map { $_ => $_ } 1..4;
    my %quarter_wide = map { $_ => 'Q' . $_ } 1..4;

    my @data = (
        id              => 'root',
        version         => '4787',
        generation_date => '2010-03-03 12:31:02 -0600 (Wed, 03 Mar 2010)',
        parent_id       => undef,
        source_file     => Locale::CLDR::LDML->_RootDir()->file( 'common', 'main', 'root.xml'),

        en_language  => 'Root',
        en_script    => undef,
        en_territory => undef,
        en_variant   => undef,

        native_language  => undef,
        native_script    => undef,
        native_territory => undef,
        native_variant   => undef,

        day_format_narrow           => 'self->day_stand_alone_narrow',
        day_format_abbreviated      => 'self->day_format_wide',
        day_format_wide             => \%day,
        day_stand_alone_narrow      => \%day,
        day_stand_alone_abbreviated => 'self->day_format_abbreviated',
        day_stand_alone_wide        => 'self->day_format_wide',

        month_format_narrow           => 'self->month_stand_alone_narrow',
        month_format_abbreviated      => 'self->month_format_wide',
        month_format_wide             => \%month,
        month_stand_alone_narrow      => \%month,
        month_stand_alone_abbreviated => 'self->month_format_abbreviated',
        month_stand_alone_wide        => 'self->month_format_wide',

        quarter_format_narrow           => 'self->quarter_stand_alone_narrow',
        quarter_format_abbreviated      => 'self->quarter_format_wide',
        quarter_format_wide             => \%quarter_wide,
        quarter_stand_alone_narrow      => \%quarter_narrow,
        quarter_stand_alone_abbreviated => 'self->quarter_format_abbreviated',
        quarter_stand_alone_wide        => 'self->quarter_format_wide',

        # day periods

        era_wide        => 'self->era_abbreviated',
        era_abbreviated => { 0 => 'BCE', 1 => 'CE' },
        era_narrow      => 'self->era_abbreviated',

        date_format_full   => 'EEEE, y MMMM dd',
        date_format_long   => 'y MMMM d',
        date_format_medium => 'y MMM d',
        date_format_short  => 'yyyy-MM-dd',

        time_format_full   => 'HH:mm:ss zzzz',
        time_format_long   => 'HH:mm:ss z',
        time_format_medium => 'HH:mm:ss',
        time_format_short  => 'HH:mm',

        datetime_format_full => '{1} {0}',
        datetime_format_long => '{1} {0}',
        datetime_format_medium => '{1} {0}',
        datetime_format_short => '{1} {0}',

        default_date_format_length => 'medium',
        default_time_format_length => 'medium',
        default_datetime_format_length => 'medium',

        available_formats => {
            d      => 'd',
            EEEd   => 'd EEE',
            h      => 'h a',
            H      => 'HH',
            hm     => 'h:mm a',
            Hm     => 'HH:mm',
            hms    => 'h:mm:ss a',
            Hms    => 'HH:mm:ss',
            M      => 'L',
            Md     => 'M-d',
            MEd    => 'E, M-d',
            MMM    => 'LLL',
            MMMd   => 'MMM d',
            MMMEd  => 'E MMM d',
            ms     => 'mm:ss',
            y      => 'y',
            yM     => 'y-M',
            yMEd   => 'EEE, y-M-d',
            yMMM   => 'y MMM',
            yMMMEd => 'EEE, y MMM d',
            yQ     => 'y Q',
            yQQQ   => 'y QQQ',
        },

        default_interval_format => "{0} \x{2013} {1}",

        interval_formats => {
            'yMMMd' => {
                'y' => "yyyy-MM-dd \x{2013} yyyy-MM-dd",
                'M' => "yyyy-MM-dd \x{2013} MM-d",
                'd' => "yyyy-MM-d \x{2013} d"
            },
            'd'      => { 'd' => "d\x{2013}d" },
            'yMMMEd' => {
                'y' => "E, yyyy-MM-dd \x{2013} E, yyyy-MM-dd",
                'M' => "E, yyyy-MM-dd \x{2013} E, yyyy-MM-dd",
                'd' => "E, yyyy-MM-dd \x{2013} E, yyyy-MM-dd"
            },
            'y'  => { 'y' => "y\x{2013}y" },
            'hv' => {
                'a' => 'h a – h a v',
                'h' => 'h–h a v'
            },
            'Hv' => {
                'a' => 'HH–HH v',
                'H' => 'HH–HH v',
            },
            'yMMMM' => {
                'y' => "yyyy-MM \x{2013} yyyy-MM",
                'M' => "yyyy-MM \x{2013} MM"
            },
            'h' => {
                'a' => 'h a – h a',
                'h' => 'h–h a'
            },
            'H' => {
                'a' => 'HH–HH',
                'H' => 'HH–HH',
            },
            'M'   => { 'M' => "M\x{2013}M" },
            'yMd' => {
                'y' => "yyyy-MM-dd \x{2013} yyyy-MM-dd",
                'M' => "yyyy-MM-dd \x{2013} MM-dd",
                'd' => "yyyy-MM-dd \x{2013} dd"
            },
            'MMM' => { 'M' => "LLL\x{2013}LLL" },
            'MEd' => {
                'M' => "E, MM-dd \x{2013} E, MM-dd",
                'd' => "E, MM-dd \x{2013} E, MM-dd"
            },
            'yM' => {
                'y' => "yyyy-MM \x{2013} yyyy-MM",
                'M' => "yyyy-MM \x{2013} MM"
            },
            'Md' => {
                'M' => "MM-dd \x{2013} MM-dd",
                'd' => "MM-dd \x{2013} dd"
            },
            'yMEd' => {
                'y' => "E, yyyy-MM-dd \x{2013} E, yyyy-MM-dd",
                'M' => "E, yyyy-MM-dd \x{2013} E, yyyy-MM-dd",
                'd' => "E, yyyy-MM-dd \x{2013} E, yyyy-MM-dd"
            },
            'hm' => {
                'a' => 'h:mm a – h:mm a',
                'h' => 'h:mm–h:mm a',
                'm' => 'h:mm–h:mm a'
            },
            'Hm' => {
                'a' => 'HH:mm–HH:mm',
                'H' => 'HH:mm–HH:mm',
                'm' => 'HH:mm–HH:mm'
            },
            'hmv' => {
                'a' => 'h:mm a – h:mm a v',
                'h' => 'h:mm–h:mm a v',
                'm' => 'h:mm–h:mm a v',
            },
            'Hmv' => {
                'a' => "HH:mm\x{2013}HH:mm v",
                'H' => "HH:mm\x{2013}HH:mm v",
                'm' => "HH:mm\x{2013}HH:mm v",
            },
            'MMMEd' => {
                'M' => "E, MM-d \x{2013} E, MM-d",
                'd' => "E, MM-d \x{2013} E, MM-d"
            },
            'MMMM' => { 'M' => "LLLL\x{2013}LLLL" },
            'MMMd' => {
                'M' => "MM-d \x{2013} MM-d",
                'd' => "MM-d \x{2013} d"
            },
            'yMMM' => {
                'y' => "yyyy-MM \x{2013} yyyy-MM",
                'M' => "yyyy-MM \x{2013} MM"
            },
        },

        field_names => {
            era   => { name => 'Era' },
            year  => { name => 'Year' },
            month => { name => 'Month' },
            week  => { name => 'Week' },
            day   => {
                name => 'Day',
                '-1' => 'Yesterday',
                '0'  => 'Today',
                '1'  => 'Tomorrow',
            },
            weekday   => { name => 'Day of the Week' },
            dayperiod => { name => 'Dayperiod' },
            hour      => { name => 'Hour' },
            minute    => { name => 'Minute' },
            second    => { name => 'Second' },
            zone      => { name => 'Zone' },
        },

        first_day_of_week => 1,
    );

    test_data( $ldml, \@data );
}

{
    my $ldml = Locale::CLDR::LDML->new_from_id('en');

    my @days = qw( Monday Tuesday Wednesday Thursday Friday Saturday Sunday );
    my %day_narrow
        = map { lc substr( $_, 0, 3 ) => substr( $_, 0, 1 ) } @days;
    my %day_abbreviated
        = map { lc substr( $_, 0, 3 ) => substr( $_, 0, 3 ) } @days;
    my %day_wide = map { lc substr( $_, 0, 3 ) => $_ } @days;

    my @months = qw( January February March April May June July August September October November December );
    my %month_narrow
        = map { $_ => substr( $months[ $_ - 1 ], 0, 1 ) } 1 .. 12;
    my %month_abbreviated
        = map { $_ => substr( $months[ $_ - 1 ], 0, 3 ) } 1 .. 12;
    my %month_wide = map { $_ => $months[ $_ - 1 ] } 1 .. 12;

    my %quarter_narrow      = map { $_ => $_ } 1 .. 4;
    my %quarter_abbreviated = map { $_ => "Q$_" } 1 .. 4;
    my %quarter_wide = map { substr( $_, 0, 1 ) => $_ }
        ( '1st quarter', '2nd quarter', '3rd quarter', '4th quarter' );

    my @data = (
        id => 'en',

        en_language  => 'English',
        en_script    => undef,
        en_territory => undef,
        en_variant   => undef,

        native_language  => 'English',
        native_script    => undef,
        native_territory => undef,
        native_variant   => undef,

        day_format_narrow           => {},
        day_format_abbreviated      => \%day_abbreviated,
        day_format_wide             => \%day_wide,
        day_stand_alone_narrow      => \%day_narrow,
        day_stand_alone_abbreviated => {},
        day_stand_alone_wide        => {},

        month_format_narrow           => {},
        month_format_abbreviated      => \%month_abbreviated,
        month_format_wide             => \%month_wide,
        month_stand_alone_narrow      => \%month_narrow,
        month_stand_alone_abbreviated => {},
        month_stand_alone_wide        => {},

        quarter_format_narrow           => {},
        quarter_format_abbreviated      => \%quarter_abbreviated,
        quarter_format_wide             => \%quarter_wide,
        quarter_stand_alone_narrow      => \%quarter_narrow,
        quarter_stand_alone_abbreviated => {},
        quarter_stand_alone_wide        => {},

        era_narrow => {
            0 => 'B',
            1 => 'A',
        },
        era_abbreviated => {
            0 => 'BC',
            1 => 'AD',
        },
        era_wide => {
            0 => 'Before Christ',
            1 => 'Anno Domini',
        },

        date_format_full   => 'EEEE, MMMM d, y',
        date_format_long   => 'MMMM d, y',
        date_format_medium => 'MMM d, y',
        date_format_short  => 'M/d/yy',

        time_format_full   => 'h:mm:ss a zzzz',
        time_format_long   => 'h:mm:ss a z',
        time_format_medium => 'h:mm:ss a',
        time_format_short  => 'h:mm a',

        datetime_format_full   => '{1} {0}',
        datetime_format_long   => '{1} {0}',
        datetime_format_medium => '{1} {0}',
        datetime_format_short  => '{1} {0}',

        default_date_format_length     => undef,
        default_time_format_length     => undef,
        default_datetime_format_length => undef,

        default_interval_format => "{0} \x{2013} {1}",

        interval_formats => {
            d => {
                d => 'd–d',
            },
            h => {
                a => 'h a – h a',
                h => 'h–h a',
            },
            hm => {
                a => 'h:mm a – h:mm a',
                h => 'h:mm–h:mm a',
                m => 'h:mm–h:mm a',
            },
            hmv => {
                a => 'h:mm a – h:mm a v',
                h => 'h:mm–h:mm a v',
                m => 'h:mm–h:mm a v',
            },
            hv => {
                a => 'h a – h a v',
                h => 'h–h a v',
            },
            M => {
                M => 'M–M',
            },
            Md => {
                d => 'M/d – M/d',
                M => 'M/d – M/d',
            },
            MEd => {
                d => 'E, M/d – E, M/d',
                M => 'E, M/d – E, M/d',
            },
            MMM => {
                M => 'MMM–MMM',
            },
            MMMd => {
                d => 'MMM d–d',
                M => 'MMM d – MMM d',
            },
            MMMEd => {
                d => 'E, MMM d – E, MMM d',
                M => 'E, MMM d – E, MMM d',
            },
            MMMM => {
                M => 'LLLL-LLLL',
            },
            y => {
                y => 'y–y',
            },
            yM => {
                M => 'M/yy – M/yy',
                y => 'M/yy – M/yy',
            },
            yMd => {
                d => 'M/d/yy – M/d/yy',
                M => 'M/d/yy – M/d/yy',
                y => 'M/d/yy – M/d/yy',
            },
            yMEd => {
                d => 'E, M/d/yy – E, M/d/yy',
                M => 'E, M/d/yy – E, M/d/yy',
                y => 'E, M/d/yy – E, M/d/yy',
            },
            yMMM => {
                M => 'MMM–MMM y',
                y => 'MMM y – MMM y',
            },
            yMMMd => {
                d => 'MMM d–d, y',
                M => 'MMM d – MMM d, y',
                y => 'MMM d, y – MMM d, y',
            },
            yMMMEd => {
                d => 'E, MMM d – E, MMM d, y',
                M => 'E, MMM d – E, MMM d, y',
                y => 'E, MMM d, y – E, MMM d, y',
            },
            yMMMM => {
                M => 'MMMM–MMMM y',
                y => 'MMMM y – MMMM y',
            },
        },

        field_names => {
            era   => { name => 'Era' },
            year  => { name => 'Year' },
            month => { name => 'Month' },
            week  => { name => 'Week' },
            day   => {
                name => 'Day',
                '-1' => 'Yesterday',
                '0'  => 'Today',
                '1'  => 'Tomorrow',
            },
            weekday   => { name => 'Day of the Week' },
            dayperiod => { name => 'AM/PM' },
            hour      => { name => 'Hour' },
            minute    => { name => 'Minute' },
            second    => { name => 'Second' },
            zone      => { name => 'Zone' },
        },

        available_formats => {
            d      => 'd',
            EEEd   => 'd EEE',
            hm     => 'h:mm a',
            Hm     => 'HH:mm',
            hms    => 'h:mm:ss a',
            Hms    => 'HH:mm:ss',
            M      => 'L',
            Md     => 'M/d',
            MEd    => 'E, M/d',
            MMM    => 'LLL',
            MMMd   => 'MMM d',
            MMMEd  => 'E, MMM d',
            ms     => 'mm:ss',
            y      => 'y',
            yM     => 'M/y',
            yMEd   => 'EEE, M/d/y',
            yMMM   => 'MMM y',
            yMMMEd => 'EEE, MMM d, y',
            yQ     => 'Q y',
            yQQQ   => 'QQQ y',
        },

        first_day_of_week => 1,
    );

    test_data( $ldml, \@data );
}

{
    my $ldml = Locale::CLDR::LDML->new_from_id('ssy');

    my @data = (
        id              => 'ssy',
        version         => '4765',
        generation_date => '2010-02-27 18:03:30 -0600 (Sat, 27 Feb 2010)',

        en_language => 'Saho',

        language  => 'ssy',
        script    => undef,
        territory => undef,
        variant   => undef,
    );

    test_data( $ldml, \@data );
}

{
    my $ldml = Locale::CLDR::LDML->new_from_id('en_GB');

    my @data = (
        id        => 'en_GB',
        language  => 'en',
        script    => undef,
        territory => 'GB',
        variant   => undef,

        available_formats => {
            Md       => 'd/M',
            MEd      => 'E, d/M',
            MMdd     => 'dd/MM',
            MMMEd    => 'E d MMM',
            MMMMd    => 'd MMMM',
            yMEd     => 'EEE, d/M/yyyy',
            yyMMM    => 'MMM yy',
            yyyyMM   => 'MM/yyyy',
            yyyyMMMM => 'MMMM y',
        },

        first_day_of_week => 7,
    );

    test_data( $ldml, \@data );
}

{
    my $ldml = Locale::CLDR::LDML->new_from_id('az');

    my @data = (
        id => 'az',

        day_format_wide => {
            sun => 'bazar',
            mon => 'bazar ertəsi',
            tue => 'çərşənbə axşamı',
            wed => 'çərşənbə',
            thu => 'cümə axşamı',
            fri => 'cümə',
            sat => 'şənbə',
        },
    );

    test_data( $ldml, \@data );
}

{
    my $ldml = Locale::CLDR::LDML->new_from_id('gaa');

    my @data = (
        id => 'gaa',

        day_format_abbreviated => {
            sun => [
                {
                    value        => 'Hog',
                    draft_status => 'unconfirmed',
                    alt_value    => undef
                }
            ],
            mon => [
                {
                    value        => 'Dzu',
                    draft_status => 'unconfirmed',
                    alt_value    => undef
                }
            ],
            tue => [
                {
                    value        => 'Dzf',
                    draft_status => 'unconfirmed',
                    alt_value    => undef
                }
            ],
            wed => [
                {
                    value        => 'Sho',
                    draft_status => 'unconfirmed',
                    alt_value    => undef
                }
            ],
            thu => [
                {
                    value        => 'Soo',
                    draft_status => 'unconfirmed',
                    alt_value    => undef
                }
            ],
            fri => [
                {
                    value        => 'Soh',
                    draft_status => 'unconfirmed',
                    alt_value    => undef
                }
            ],
            sat => [
                {
                    value        => 'Ho',
                    draft_status => 'unconfirmed',
                    alt_value    => undef
                }
            ],
        },
    );

    test_data( $ldml, \@data );
}

{
    my $ldml = Locale::CLDR::LDML->new_from_id('ve');

    my $x      = 1;
    my %months = map {
        $x++ => [
            {
                value        => $_,
                draft_status => 'unconfirmed',
                'alt_value'  => undef,
            }
            ]
    } qw( Pha Luh Ṱhf Lam Shu Lwi Lwa Ṱha Khu Tsh Ḽar Nye );

    my @data = (
        id => 've',

        month_format_abbreviated => \%months,
    );

    test_data( $ldml, \@data );
}

{
    my $ldml = Locale::CLDR::LDML->new_from_id('zh_Hant');

    my @data = (
        field_names => {
            era   => { name => '年代' },
            year  => { name => '年' },
            month => { name => '月' },
            week  => { name => '週' },
            day   => {
                name => '日',
                '-3' => '大前天',
                '-2' => '前天',
                '-1' => '昨天',
                '0'  => '今天',
                '1'  => '明天',
                '2'  => '後天',
                '3'  => '大後天',
            },
            weekday   => { name => '週天' },
            dayperiod => { name => '上午/下午' },
            hour      => { name => '小時' },
            minute    => { name => '分鐘' },
            second    => { name => '秒' },
            zone      => { name => '區域' },
        },
    );

    test_data( $ldml, \@data );
}

{
    my $ldml = Locale::CLDR::LDML->new_from_id('de_AT');


    my @data = (
        id => 'de_AT',

        month_format_wide => { 1 => 'Jänner' },
    );

    test_data( $ldml, \@data );
}

{
    my $ldml = Locale::CLDR::LDML->new_from_id('bg');

    my @data = (
        era_narrow => {
            1 => [
                {
                    value        => 'сл.н.е.',
                    draft_status => 'contributed',
                    alt_value    => undef
                },
            ],
        },
    );

    test_data( $ldml, \@data );
}

done_testing();

sub test_data {
    my $ldml = shift;
    my $data = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    for ( my $i = 0; $i < @{$data}; $i += 2 ) {
        my $attr   = $data->[$i];
        my $expect = $data->[ $i + 1 ];

        my $meta_attr = $ldml->meta()->get_attribute($attr);

        die "No attribute named $attr\n"
            unless $meta_attr;

        die "No type constraint for $attr\n"
            unless $meta_attr->type_constraint();

        my $type_name = $meta_attr->type_constraint()->name();

        if ( $attr eq 'interval_formats' || $attr eq 'field_names' ) {
            check_hoh_of_nodesets(
                $ldml->$attr(),
                $expect,
                "$attr in " . $ldml->id()
            );
        }
        elsif ( $type_name =~ /HashRefOfNodeSetsOrAlias/ ) {
            check_nodesets_or_alias(
                $ldml->$attr(),
                $expect,
                "$attr in " . $ldml->id()
            );
        }
        elsif ( $type_name =~ /NodeSetOrAlias/ ) {
            check_nodeset_or_alias(
                $ldml->$attr(),
                $expect,
                "$attr in " . $ldml->id()
            );
        }
        elsif ( ref $expect ) {
            is_deeply(
                $ldml->$attr(),
                $expect,
                "$attr in " . $ldml->id()
            );
        }
        else {
            is(
                $ldml->$attr(),
                $expect,
                "$attr in " . $ldml->id()
            );
        }
    }
}

sub check_nodesets_or_alias {
    my $got    = shift;
    my $expect = shift;
    my $desc   = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    if ( blessed $got ) {
        check_alias( $got, $expect, $desc );
        return;
    }

    my %munged;

    for my $key ( keys %{$got} ) {
        $munged{$key} = _simplify_nodeset($got->{$key});
    }

    is_deeply(
        \%munged,
        $expect,
        $desc
    );
}

sub check_nodeset_or_alias {
    my $got    = shift;
    my $expect = shift;
    my $desc   = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    if ( $got->isa('Locale::CLDR::LDML::Alias') ) {
        check_alias( $got, $expect, $desc );
        return;
    }

    my $simple = _simplify_nodeset($got);

    if ( ref $simple ) {
        is_deeply(
            $simple,
            $expect,
            $desc
        );
    }
    else {
        is(
            $simple,
            $expect,
            $desc
        );
    }
}

sub check_alias {
    my $got    = shift;
    my $expect = shift;
    my $desc   = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $alias = join '->', $got->id(), $got->method();

    is(
        $alias,
        $expect,
        $desc
    );
}

sub check_hoh_of_nodesets {
    my $got    = shift;
    my $expect = shift;
    my $desc   = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my %munged;
    for my $key1 ( keys %{$got} ) {
        for my $key2 ( keys %{ $got->{$key1} } ) {
            $munged{$key1}{$key2} = _simplify_nodeset( $got->{$key1}{$key2} );
        }
    }

    is_deeply(
        \%munged,
        $expect,
        $desc
    );
}

sub _simplify_nodeset {
    my $ns = shift;

    my @nodes = $ns->nodes();

    if ( @nodes == 1 && !$nodes[0]->is_draft() ) {
        return $nodes[0]->value();
    }
    else {
        return [
            map {
                {
                    value        => $_->value(),
                    draft_status => $_->draft_status(),
                    alt_value    => $_->alt_value()
                }
                } @nodes
        ];
    }
}
