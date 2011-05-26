use strict; 
use warnings;

use Test::More tests => 166;

use Text::Table;

print "# Version: $Text::Table::VERSION\n";

# internal parser functions

# undefined argument
{
    my $test_name = "Undefined argument";
    my $spec = Text::Table::_parse_spec();
    # TEST
    is( scalar @{ $spec->{ title}}, 0, "$test_name - Title");
    # TEST
    is( $spec->{ align}, 'auto', "$test_name - Auto");
    # TEST
    is( scalar @{ $spec->{ sample}}, 0, "$test_name - sample");
    $spec = Text::Table::_parse_spec( undef);
    # TEST
    is( scalar @{ $spec->{ title}}, 0, "$test_name - sNo titles");
    # TEST
    is( $spec->{ align}, 'auto', "$test_name - sauto");
    # TEST
    is( scalar @{ $spec->{ sample}}, 0, "$test_name - sNo samples");
}

# other functions
use constant T_EMPTY  => <<EOT1;
EOT1
use constant T_SINGLE => <<EOT2;
single line title
EOT2
use constant T_MULTI  => <<EOT3;

multi-line
<not the alignment>
title

EOT3
use constant S_EMPTY => <<EOS1;
&
EOS1
use constant S_SINGLE => <<EOS2;
&num(,)
00.000
EOS2
use constant S_MULTI  => <<EOS3;
&
xxxx
0.1

EOS3

# TEST:$n_titles=3;
use constant TITLES => ( T_EMPTY, T_SINGLE, T_MULTI);
use constant TITLE_ANS => map { chomp; $_} TITLES;
# TEST:$n_samples=3;
use constant SAMPLES => ( S_EMPTY, S_SINGLE, S_MULTI);
use constant SAMPLE_ANS => ( "", "00.000", "xxxx\n0.1\n");
use constant ALIGN_ANS => ( "auto", "num(,)", "auto");

# TEST*2*$n_titles
# TEST*3*$n_samples
# TEST*2*3*$n_titles*$n_samples

my @title_ans = TITLE_ANS;
{
    my $count = 0;
    for my $title ( TITLES ) {
        $title .= "&" if $title =~ /^&/m;
        my $spec = Text::Table::_parse_spec( $title);
        is ( join( "\n", @{ $spec->{ title}}), shift @title_ans, "Title $count");
        is ( join( "\n", @{ $spec->{ sample}}), q//, "Sample $count");
    }
    continue {
        $count++;
    }
}

my @sample_ans = SAMPLE_ANS;
my @align_ans = ALIGN_ANS;

{
    my $count = 0;
    for my $sample ( SAMPLES ) {
        my $spec = Text::Table::_parse_spec( $sample);
        is( join( "\n", @{ $spec->{ title}}), '', "Title $count");
        is( join( "\n", @{ $spec->{ sample}}), shift @sample_ans, "Sample $count");
        is( $spec->{ align}, shift @align_ans, "Align $count");
    }
    continue {
        $count++;
    }
}

@title_ans = TITLE_ANS;
for my $title ( TITLES ) {
    my $title_ans = shift @title_ans;
    my @sample_ans = SAMPLE_ANS;
    my @align_ans = ALIGN_ANS;
    for my $sample ( SAMPLES ) {
        my $spec = Text::Table::_parse_spec( "$title$sample");
        is( join( "\n", @{ $spec->{ title}}), $title_ans, "Title Ans");
        is( join( "\n", @{ $spec->{ sample}}), shift @sample_ans, "Sample");
        is( join( "\n", $spec->{ align}), shift @align_ans, "Align");
    }
    @sample_ans = SAMPLE_ANS;
    @align_ans = ALIGN_ANS;
    chomp $title;
    for my $sample ( SAMPLES ) {
        chomp $sample;
        chomp( my $sample_ans = shift @sample_ans);
        my $spec = Text::Table::_parse_spec( "$title\n$sample");
        is( join( "\n", @{ $spec->{ title}}), $title_ans, "Title");
        is( join( "\n", @{ $spec->{ sample}}), $sample_ans, "Sample");
        is( join( "\n", $spec->{ align}), shift @align_ans, "Align");
    }
}

{
    my $tb = Text::Table->new;

    # TEST
    is( ref $tb, 'Text::Table', "Class is OK.");

    # TEST
    is( $tb->n_cols, 0, "n_cols == 0");

    # TEST
    is( $tb->height, 0, "height is 0");

    # TEST
    is( $tb->width, 0, "width is 0");

    # TEST
    is( $tb->stringify, '', "stringify is empty");

    # empty table with non-empty data array (auto-initialisation)
    $tb->load(
    '1 2 3',
    [4, 5, 6],
    '7 8',
    );

    # TEST
    is( $tb->n_cols, 3, "n_cols");

    # TEST
    is( $tb->height, 3, "height");

    # TEST
    is( $tb->width, 5, "width");

    # TEST
    is( $tb->stringify, "1 2 3\n4 5 6\n7 8  \n", "stringify is OK.");

}

# run this again with undefined $/, see if there's a warning
{
    local $/;
    my $warncount = 0;
    local $SIG{__WARN__} = sub { ++ $warncount };

    my $tb = Text::Table->new;

    $tb->load(
    '1 2 3',
    [4, 5, 6],
    '7 8',
    );

    # TEST
    is ($warncount, 0, "Warn count");
}

# single title-less column
my $tb = Text::Table->new( '');
# TEST
is( $tb->n_cols, 1, "n_cols");
# TEST
is( $tb->height, 0, "height");
# TEST
is( $tb->width, 0, "width");
# TEST
is( $tb->stringify, '', "stringify");

# same with some data (more than needed, actually)
$tb->load(
   "1 2 3",
   [4, 5, 6],
   [7, 8],
);
# TEST
is( $tb->n_cols, 1, "n_cols == 1");
# TEST
is( $tb->height, 3, "height == 3");
# TEST
is( $tb->width, 1, "width == 1");
# TEST
is( $tb->stringify, "1\n4\n7\n", "stringify");

$tb->clear;
# TEST
is( $tb->n_cols, 1, "n_cols after clear");
# TEST
is( $tb->height, 0, "height after clear");
# TEST
is( $tb->width, 0, "width after clear");
# TEST
is( $tb->stringify, '', "stringify after clear");

# do samples work?
$tb = Text::Table->new( { sample => 'xxxx'});
$tb->load( '0');
# TEST
is( $tb->width, 4, 'width samples');
# TEST
is( $tb->height, 1, 'height == 1');
$tb->load( '12345');
# TEST
is( $tb->width, 5, 'width == 5');
# TEST
is( $tb->height, 2, 'height == 2');

# samples should be considered in title alignment even with no data
{
    my $title;
    $tb = Text::Table->new( { title => 'x', sample => 'xxx'});
    chomp( $title = $tb->title( 0));

    # TEST
    is( $title, 'x  ' , "samples should be in text aling - title");
}

# load without data
$tb = Text::Table->new();
{
    my $warncount = 0;
    local $SIG{__WARN__} = sub { ++ $warncount };
    $tb->load();
    # TEST
    is ($warncount, 0, 'no warnings');
    $tb->load([]);
    # TEST
    is ($warncount, 0, 'no warnings');
}

# overall functional check with typical table
use constant TYP_TITLE => 
    { title => 'name', align => 'left'},
    { title => 'age'},
    "salary\n in \$",
    "gibsnich",
;
use constant TYP_DATA =>
    [ qw( fred 28 1256)],
    "mary_anne 34 445.02",
    [ qw( scroogy 87 356.10)],
    "frosty 16 9999.9",
;
use constant TYP_TITLE_ANS => <<'EOT';
name      age salary  gibsnich
               in $           
EOT
use constant TYP_BODY_ANS => <<'EOT';
fred      28  1256            
mary_anne 34   445.02         
scroogy   87   356.10         
frosty    16  9999.9          
EOT
use constant TYP_ANS => TYP_TITLE_ANS . TYP_BODY_ANS;

$tb = Text::Table->new( TYP_TITLE);
# TEST
is( $tb->n_cols, 4, 'n_cols');
# TEST
is( $tb->height, 2, 'height');
# TEST
is( $tb->width, 24, 'width');

$tb->load( TYP_DATA);
# TEST
is( $tb->n_cols, 4, 'n_cols after TYP_DATA');
# TEST
is( $tb->height, 6, 'height after TYP_DATA');
# TEST
is( $tb->width, 30, 'width after TYP_DATA');
# TEST
is( $tb->stringify, TYP_ANS, 'stringify after TYP_ANS');

$tb->clear;
# TEST
is( $tb->n_cols, 4, 'n_cols after clear');
# TEST
is( $tb->height, 2, 'height after clear');
# TEST
is( $tb->width, 24, 'width after clear');

# access parts of table
$tb->load( TYP_DATA);

# TEST
is( join( '', $tb->title), TYP_TITLE_ANS, 'TYP_TITLE_ANS');
# TEST
is( join( '', $tb->body), TYP_BODY_ANS, 'TYP_BODY_ANS');
my ( $first_title, $last_title) = ( TYP_TITLE_ANS =~ /(.*\n)/g)[ 0, -1];
my ( $first_body, $last_body) = ( TYP_BODY_ANS =~ /(.*\n)/g)[ 0, -1];
# TEST
is( ($tb->title( 0))[ 0], $first_title, 'first_title');
# TEST
is( ($tb->body( 0))[ 0], $first_body, 'first_body');
# TEST
is( ($tb->table( 0))[ 0], $first_title, 'first_title');
# TEST
is( ($tb->title( -1))[ 0], $last_title, 'last_title');
# TEST
is( ($tb->body( -1))[ 0], $last_body, 'last_body');
# TEST
is( ($tb->table( -1))[ 0], $last_body, 'last_body');

### separators and rules
$tb = Text::Table->new( 'aaa', \' x ', 'bbb');
# TEST
is( $tb->rule,            "    x    \n", 'rule 1');
# TEST
is( $tb->rule( '='     ), "====x====\n", 'rule 2');
# TEST
is( $tb->rule( '=', '+'), "====+====\n", 'rule 3');

$tb->add( 'tttttt', '');

# TEST
is( $tb->rule, "       x    \n", 'rule 4');

# multiple separators
$tb = Text::Table->new( 'aaa', \' xxxxx ', \' y ', 'bbb');
# TEST
is( $tb->rule, "    y    \n", 'rule 5');

# different separators in head and body
$tb = Text::Table->new( 'aaa', \"x\ny", 'bbb');

# TEST
is( $tb->rule, "   x   \n", 'rule 6');

# TEST
is( $tb->body_rule, "   y   \n", 'rule 7');

### colrange
$tb = Text::Table->new( 'aaa', \"|", 'bbb');

# TEST
is( ($tb->colrange( 0))[ 0], 0, 'colrange 1');

# TEST
is( ($tb->colrange( 0))[ 1], 3, 'colrange 2');

# TEST
is( ($tb->colrange( 1))[ 0], 4, 'colrange 3');

# TEST
is( ($tb->colrange( 1))[ 1], 3, 'colrange 4');

# TEST
is( ($tb->colrange( 2))[ 0], 7, 'colrange 5');

# TEST
is( ($tb->colrange( 2))[ 1], 0, 'colrange 6');

# TEST
is( ($tb->colrange( 9))[ 0], 7, 'colrange 7');

# TEST
is( ($tb->colrange( 9))[ 1], 0, 'colrange 8');

# TEST
is( ($tb->colrange( -1))[ 0], 4, 'colrange 9');

# TEST
is( ($tb->colrange( -1))[ 1], 3, 'colrange 10');

$tb->add( 'xxxxxx', 'yy');

# TEST
is( ($tb->colrange( 0))[ 0], 0, 'colrange 1');

# TEST
is( ($tb->colrange( 0))[ 1], 6, 'colrange 2');

# TEST
is( ($tb->colrange( 1))[ 0], 7, 'colrange 3');

# TEST
is( ($tb->colrange( 1))[ 1], 3, 'colrange 4');

# TEST
is( ($tb->colrange( 2))[ 0], 10, 'colrange 5');

# TEST
is( ($tb->colrange( 2))[ 1], 0, 'colrange 6');

# body-title alignment

my $title;

$tb = Text::Table->new( { title => 'x', align_title => 'right' });
$tb->add( 'xxx');
chomp( $title = $tb->title( 0));

# TEST
is( $title, '  x', 'title');

$tb = Text::Table->new( { title => 'x', align_title => 'center' });
$tb->add( 'xxx');
chomp( $title = $tb->title( 0));

# TEST
is( $title, ' x ', 'title 2');

$tb = Text::Table->new( { title => 'x', align_title => 'left' });
$tb->add( 'xxx');
chomp( $title = $tb->title( 0));

# TEST
is( $title, 'x  ', 'title 3');

$tb = Text::Table->new( { title => 'x' }); # default?
$tb->add( 'xxx');
chomp( $title = $tb->title( 0));

# TEST
is( $title, 'x  ', 'title 4');

$tb = Text::Table->new( { title => "x\nxxx", align_title_lines => 'right'});
chomp( ( $title) = $tb->title); # first line

# TEST
is( $title, '  x', 'title 5');

$tb = Text::Table->new( { title => "x\nxxx", align_title_lines => 'center'});
chomp( ( $title) = $tb->title); # first line

# TEST
is( $title, ' x ', 'title 6');

$tb = Text::Table->new( { title => "x\nxxx", align_title_lines => 'left'});
chomp( ( $title) = $tb->title); # first line

# TEST
is( $title, 'x  ', 'title 7');

# default?
$tb = Text::Table->new( { title => "x\nxxx"});
chomp( ( $title) = $tb->title); # first line

# TEST
is( $title, 'x  ', 'title 8');

# default propagation from 'align_title'
$tb = Text::Table->new( { title => "x\nxxx", align_title => 'right'});
chomp( ( $title) = $tb->title);

# TEST
is( $title, '  x', 'title 9');

### column selection

$tb = Text::Table->new( '', '');
$tb->load( [ 0, 1], [ undef, 2], [ '', 3]);


# TEST
is( $tb->select(   0,    1 )->n_cols, 2, 'n_cols 1');

# TEST
is( $tb->select( [ 0],   1 )->n_cols, 1, 'n_cols 2');

# TEST
is( $tb->select(   0,  [ 1])->n_cols, 2, 'n_cols 3');

# TEST
is( $tb->select( [ 0], [ 1])->n_cols, 1, 'n_cols 4');

# TEST
is( $tb->select( [ 0,    1])->n_cols, 0, 'n_cols 5');

# multiple selection
my $mult = $tb->select( 0, 1, 0, 1);

# TEST
is( $mult->n_cols, 4, 'n_cols 4');

# TEST
is( $mult->height, 3, 'height 3');

# TEST
is( $mult->stringify, <<EOT, 'stringify');
0 1 0 1
  2   2
  3   3
EOT

# overloading
$tb = Text::Table->new( TYP_TITLE);
$tb->load( TYP_DATA);

# TEST
is( "$tb", TYP_ANS, 'TYP_ANS');

# multi-line rows
$tb = Text::Table->new( qw( A B C ) );
$tb->load( [ "1", "2", "3" ],
           [ "a\nb", "c", "d" ],
           [ "e", "f\ng", "h" ],
           [ "i", "j", "k\nl" ],
           [ "m", "n", "o" ] );

# TEST
is( "$tb", <<EOT, "Table after spaces");
A B C
1 2 3
a c d
b    
e f h
  g  
i j k
    l
m n o
EOT

# Chained ->load call

# TEST
is( "" . Text::Table
             -> new( TYP_TITLE )
             -> load( TYP_DATA ),
    TYP_ANS, "All in one" );

# Chained ->add call

# TEST
is( "" . Text::Table
             -> new( "x" x 10 )
             -> add( "y" x 10 ),
    "x" x 10 . "\n" . "y" x 10 . "\n", "All in one - 2");
