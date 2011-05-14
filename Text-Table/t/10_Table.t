use strict; 
use warnings;

use Test::More;
my $n_tests;
BEGIN { $n_tests = 0 }

use Text::Table;

print "# Version: $Text::Table::VERSION\n";

# internal parser functions

# undefined argument
BEGIN { $n_tests += 6 }
my $spec = Text::Table::_parse_spec();
is( scalar @{ $spec->{ title}}, 0, 'Title');
is( $spec->{ align}, 'auto', 'Auto');
is( scalar @{ $spec->{ sample}}, 0, 'sample');
$spec = Text::Table::_parse_spec( undef);
is( scalar @{ $spec->{ title}}, 0, 'No titles');
is( $spec->{ align}, 'auto', 'auto');
is( scalar @{ $spec->{ sample}}, 0, 'No samples');

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

use constant TITLES => ( T_EMPTY, T_SINGLE, T_MULTI);
use constant TITLE_ANS => map { chomp; $_} TITLES;
use constant SAMPLES => ( S_EMPTY, S_SINGLE, S_MULTI);
use constant SAMPLE_ANS => ( "", "00.000", "xxxx\n0.1\n");
use constant ALIGN_ANS => ( "auto", "num(,)", "auto");

BEGIN {
    my $n_titles = @{ [ TITLES]};
    my $n_samples = @{ [ SAMPLES]};
    $n_tests += 2*$n_titles;
    $n_tests += 3*$n_samples;
    $n_tests += 2*3*$n_titles*$n_samples;
}

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

# functions with empty table
BEGIN { $n_tests += 5 }

my $tb;
$tb = Text::Table->new;
is( ref $tb, 'Text::Table', "Class is OK.");

is( $tb->n_cols, 0, "n_cols == 0");
is( $tb->height, 0, "height is 0");
is( $tb->width, 0, "width is 0");
is( $tb->stringify, '', "stringify is empty");

# empty table with non-empty data array (auto-initialisation)
BEGIN { $n_tests += 4 }
$tb->load(
'1 2 3',
[4, 5, 6],
'7 8',
);
is( $tb->n_cols, 3, "n_cols");
is( $tb->height, 3, "height");
is( $tb->width, 5, "width");
is( $tb->stringify, "1 2 3\n4 5 6\n7 8  \n", "stringify is OK.");

# run this again with undefined $/, see if there's a warning
BEGIN { $n_tests += 1 }
{
    local $/;
    my $warncount = 0;
    local $SIG{__WARN__} = sub { ++ $warncount };

    $tb = Text::Table->new;

    $tb->load(
    '1 2 3',
    [4, 5, 6],
    '7 8',
    );

    is ($warncount, 0, "Warn count");
}

# single title-less column
BEGIN { $n_tests += 4 }
$tb = Text::Table->new( '');
is( $tb->n_cols, 1, "n_cols");
is( $tb->height, 0, "height");
is( $tb->width, 0, "width");
is( $tb->stringify, '', "stringify");

# same with some data (more than needed, actually)
BEGIN { $n_tests += 8 }
$tb->load(
   "1 2 3",
   [4, 5, 6],
   [7, 8],
);
is( $tb->n_cols, 1, "n_cols == 1");
is( $tb->height, 3, "height == 3");
is( $tb->width, 1, "width == 1");
is( $tb->stringify, "1\n4\n7\n", "stringify");

$tb->clear;
is( $tb->n_cols, 1, "n_cols after clear");
is( $tb->height, 0, "height after clear");
is( $tb->width, 0, "width after clear");
is( $tb->stringify, '', "stringify after clear");

# do samples work?
BEGIN { $n_tests += 5 }
$tb = Text::Table->new( { sample => 'xxxx'});
$tb->load( '0');
is( $tb->width, 4, 'width samples');
is( $tb->height, 1, 'height == 1');
$tb->load( '12345');
is( $tb->width, 5, 'width == 5');
is( $tb->height, 2, 'height == 2');
# samples should be considered in title alignment even with no data
my $tit;
$tb = Text::Table->new( { title => 'x', sample => 'xxx'});
chomp( $tit = $tb->title( 0));
is( $tit, 'x  ' , 'title');

# load without data
$tb = Text::Table->new();
BEGIN { $n_tests += 2 }
{
    my $warncount = 0;
    local $SIG{__WARN__} = sub { ++ $warncount };
    $tb->load();
    is ($warncount, 0, 'no warnings');
    $tb->load([]);
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

BEGIN { $n_tests += 3 }
$tb = Text::Table->new( TYP_TITLE);
is( $tb->n_cols, 4, 'n_cols');
is( $tb->height, 2, 'height');
is( $tb->width, 24, 'width');

BEGIN { $n_tests += 4 }
$tb->load( TYP_DATA);
is( $tb->n_cols, 4, 'n_cols after TYP_DATA');
is( $tb->height, 6, 'height after TYP_DATA');
is( $tb->width, 30, 'width after TYP_DATA');
is( $tb->stringify, TYP_ANS, 'stringify after TYP_ANS');

BEGIN { $n_tests += 3 }
$tb->clear;
is( $tb->n_cols, 4, 'n_cols after clear');
is( $tb->height, 2, 'height after clear');
is( $tb->width, 24, 'width after clear');

# access parts of table
BEGIN { $n_tests += 8 }
$tb->load( TYP_DATA);

is( join( '', $tb->title), TYP_TITLE_ANS, 'TYP_TITLE_ANS');
is( join( '', $tb->body), TYP_BODY_ANS, 'TYP_BODY_ANS');
my ( $first_title, $last_title) = ( TYP_TITLE_ANS =~ /(.*\n)/g)[ 0, -1];
my ( $first_body, $last_body) = ( TYP_BODY_ANS =~ /(.*\n)/g)[ 0, -1];
is( ($tb->title( 0))[ 0], $first_title, 'first_title');
is( ($tb->body( 0))[ 0], $first_body, 'first_body');
is( ($tb->table( 0))[ 0], $first_title, 'first_title');
is( ($tb->title( -1))[ 0], $last_title, 'last_title');
is( ($tb->body( -1))[ 0], $last_body, 'last_body');
is( ($tb->table( -1))[ 0], $last_body, 'last_body');

### separators and rules
BEGIN { $n_tests += 7 }
$tb = Text::Table->new( 'aaa', \' x ', 'bbb');
is( $tb->rule,            "    x    \n", 'rule 1');
is( $tb->rule( '='     ), "====x====\n", 'rule 2');
is( $tb->rule( '=', '+'), "====+====\n", 'rule 3');

$tb->add( 'tttttt', '');
is( $tb->rule, "       x    \n", 'rule 4');

# multiple separators
$tb = Text::Table->new( 'aaa', \' xxxxx ', \' y ', 'bbb');
is( $tb->rule, "    y    \n", 'rule 5');

# different separators in head and body
$tb = Text::Table->new( 'aaa', \"x\ny", 'bbb');
is( $tb->rule, "   x   \n", 'rule 6');
is( $tb->body_rule, "   y   \n", 'rule 7');

### colrange
BEGIN { $n_tests += 16 }
$tb = Text::Table->new( 'aaa', \"|", 'bbb');
is( ($tb->colrange( 0))[ 0], 0, 'colrange 1');
is( ($tb->colrange( 0))[ 1], 3, 'colrange 2');
is( ($tb->colrange( 1))[ 0], 4, 'colrange 3');
is( ($tb->colrange( 1))[ 1], 3, 'colrange 4');
is( ($tb->colrange( 2))[ 0], 7, 'colrange 5');
is( ($tb->colrange( 2))[ 1], 0, 'colrange 6');
is( ($tb->colrange( 9))[ 0], 7, 'colrange 7');
is( ($tb->colrange( 9))[ 1], 0, 'colrange 8');
is( ($tb->colrange( -1))[ 0], 4, 'colrange 9');
is( ($tb->colrange( -1))[ 1], 3, 'colrange 10');

$tb->add( 'xxxxxx', 'yy');
is( ($tb->colrange( 0))[ 0], 0, 'colrange 1');
is( ($tb->colrange( 0))[ 1], 6, 'colrange 2');
is( ($tb->colrange( 1))[ 0], 7, 'colrange 3');
is( ($tb->colrange( 1))[ 1], 3, 'colrange 4');
is( ($tb->colrange( 2))[ 0], 10, 'colrange 5');
is( ($tb->colrange( 2))[ 1], 0, 'colrange 6');

# body-title alignment
BEGIN { $n_tests += 4 }

$tb = Text::Table->new( { title => 'x', align_title => 'right' });
$tb->add( 'xxx');
chomp( $tit = $tb->title( 0));
is( $tit, '  x', 'title');

$tb = Text::Table->new( { title => 'x', align_title => 'center' });
$tb->add( 'xxx');
chomp( $tit = $tb->title( 0));
is( $tit, ' x ', 'title 2');

$tb = Text::Table->new( { title => 'x', align_title => 'left' });
$tb->add( 'xxx');
chomp( $tit = $tb->title( 0));
is( $tit, 'x  ', 'title 3');

$tb = Text::Table->new( { title => 'x' }); # default?
$tb->add( 'xxx');
chomp( $tit = $tb->title( 0));
is( $tit, 'x  ', 'title 4');

# title-internal alignment
BEGIN { $n_tests += 5 }

$tb = Text::Table->new( { title => "x\nxxx", align_title_lines => 'right'});
chomp( ( $tit) = $tb->title); # first line
is( $tit, '  x', 'title 5');

$tb = Text::Table->new( { title => "x\nxxx", align_title_lines => 'center'});
chomp( ( $tit) = $tb->title); # first line
is( $tit, ' x ', 'title 6');

$tb = Text::Table->new( { title => "x\nxxx", align_title_lines => 'left'});
chomp( ( $tit) = $tb->title); # first line
is( $tit, 'x  ', 'title 7');

# default?
$tb = Text::Table->new( { title => "x\nxxx"});
chomp( ( $tit) = $tb->title); # first line
is( $tit, 'x  ', 'title 8');

# default propagation from 'align_title'
$tb = Text::Table->new( { title => "x\nxxx", align_title => 'right'});
chomp( ( $tit) = $tb->title);
is( $tit, '  x', 'title 9');

### column selection
BEGIN { $n_tests += 5 }

$tb = Text::Table->new( '', '');
$tb->load( [ 0, 1], [ undef, 2], [ '', 3]);

is( $tb->select(   0,    1 )->n_cols, 2, 'n_cols 1');
is( $tb->select( [ 0],   1 )->n_cols, 1, 'n_cols 2');
is( $tb->select(   0,  [ 1])->n_cols, 2, 'n_cols 3');
is( $tb->select( [ 0], [ 1])->n_cols, 1, 'n_cols 4');
is( $tb->select( [ 0,    1])->n_cols, 0, 'n_cols 5');

# multiple selection
BEGIN { $n_tests += 3 }
my $mult = $tb->select( 0, 1, 0, 1);
is( $mult->n_cols, 4, 'n_cols 4');
is( $mult->height, 3, 'height 3');
is( $mult->stringify, <<EOT, 'stringify');
0 1 0 1
  2   2
  3   3
EOT

# overloading
BEGIN { $n_tests += 1 }
$tb = Text::Table->new( TYP_TITLE);
$tb->load( TYP_DATA);
is( "$tb", TYP_ANS, 'TYP_ANS');

# multi-line rows
BEGIN { $n_tests += 1 }
$tb = Text::Table->new( qw( A B C ) );
$tb->load( [ "1", "2", "3" ],
           [ "a\nb", "c", "d" ],
           [ "e", "f\ng", "h" ],
           [ "i", "j", "k\nl" ],
           [ "m", "n", "o" ] );
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
BEGIN { $n_tests += 1 }
is( "" . Text::Table
             -> new( TYP_TITLE )
             -> load( TYP_DATA ),
    TYP_ANS, "All in one" );

# Chained ->add call
BEGIN { $n_tests += 1 }
is( "" . Text::Table
             -> new( "x" x 10 )
             -> add( "y" x 10 ),
    "x" x 10 . "\n" . "y" x 10 . "\n", "All in one - 2");

BEGIN { plan tests => $n_tests }
