use strict; use warnings;
use Test;
my $n_tests;
BEGIN { $n_tests = 0 }

use Text::Table;

print "# Version: $Text::Table::VERSION\n";

# internal parser functions

# undefined argument
BEGIN { $n_tests += 6 }
my $spec = Text::Table::_parse_spec();
ok( scalar @{ $spec->{ title}}, 0);
ok( $spec->{ align}, 'auto');
ok( scalar @{ $spec->{ sample}}, 0);
$spec = Text::Table::_parse_spec( undef);
ok( scalar @{ $spec->{ title}}, 0);
ok( $spec->{ align}, 'auto');
ok( scalar @{ $spec->{ sample}}, 0);

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
for my $title ( TITLES ) {
    $title .= "&" if $title =~ /^&/m;
    my $spec = Text::Table::_parse_spec( $title);
    ok( join( "\n", @{ $spec->{ title}}), shift @title_ans);
    ok( join( "\n", @{ $spec->{ sample}}), '');
}

my @sample_ans = SAMPLE_ANS;
my @align_ans = ALIGN_ANS;
for my $sample ( SAMPLES ) {
    my $spec = Text::Table::_parse_spec( $sample);
    ok( join( "\n", @{ $spec->{ title}}), '');
    ok( join( "\n", @{ $spec->{ sample}}), shift @sample_ans);
    ok( $spec->{ align}, shift @align_ans);
}

@title_ans = TITLE_ANS;
for my $title ( TITLES ) {
    my $title_ans = shift @title_ans;
    my @sample_ans = SAMPLE_ANS;
    my @align_ans = ALIGN_ANS;
    for my $sample ( SAMPLES ) {
        my $spec = Text::Table::_parse_spec( "$title$sample");
        ok( join( "\n", @{ $spec->{ title}}), $title_ans);
        ok( join( "\n", @{ $spec->{ sample}}), shift @sample_ans);
        ok( join( "\n", $spec->{ align}), shift @align_ans);
    }
    @sample_ans = SAMPLE_ANS;
    @align_ans = ALIGN_ANS;
    chomp $title;
    for my $sample ( SAMPLES ) {
        chomp $sample;
        chomp( my $sample_ans = shift @sample_ans);
        my $spec = Text::Table::_parse_spec( "$title\n$sample");
        ok( join( "\n", @{ $spec->{ title}}), $title_ans);
        ok( join( "\n", @{ $spec->{ sample}}), $sample_ans);
        ok( join( "\n", $spec->{ align}), shift @align_ans);
    }
}

# functions with empty table
BEGIN { $n_tests += 5 }

my $tb;
$tb = Text::Table->new;
ok( ref $tb, 'Text::Table');

ok( $tb->n_cols, 0);
ok( $tb->height, 0);
ok( $tb->width, 0);
ok( $tb->stringify, '');

# empty table with non-empty data array (auto-initialisation)
BEGIN { $n_tests += 4 }
$tb->load(
'1 2 3',
[4, 5, 6],
'7 8',
);
ok( $tb->n_cols, 3);
ok( $tb->height, 3);
ok( $tb->width, 5);
ok( $tb->stringify, "1 2 3\n4 5 6\n7 8  \n");

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
    ok($warncount, 0);
}

# single title-less column
BEGIN { $n_tests += 4 }
$tb = Text::Table->new( '');
ok( $tb->n_cols, 1);
ok( $tb->height, 0);
ok( $tb->width, 0);
ok( $tb->stringify, '');

# same with some data (more than needed, actually)
BEGIN { $n_tests += 8 }
$tb->load(
   "1 2 3",
   [4, 5, 6],
   [7, 8],
);
ok( $tb->n_cols, 1);
ok( $tb->height, 3);
ok( $tb->width, 1);
ok( $tb->stringify, "1\n4\n7\n");

$tb->clear;
ok( $tb->n_cols, 1);
ok( $tb->height, 0);
ok( $tb->width, 0);
ok( $tb->stringify, '');

# do samples work?
BEGIN { $n_tests += 5 }
$tb = Text::Table->new( { sample => 'xxxx'});
$tb->load( '0');
ok( $tb->width, 4);
ok( $tb->height, 1);
$tb->load( '12345');
ok( $tb->width, 5);
ok( $tb->height, 2);
# samples should be considered in title alignment even with no data
my $tit;
$tb = Text::Table->new( { title => 'x', sample => 'xxx'});
chomp( $tit = $tb->title( 0));
ok( $tit, 'x  ');

# load without data
$tb = Text::Table->new();
BEGIN { $n_tests += 2 }
{
    my $warncount = 0;
    local $SIG{__WARN__} = sub { ++ $warncount };
    $tb->load();
    ok($warncount, 0);
    $tb->load([]);
    ok($warncount, 0);
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
ok( $tb->n_cols, 4);
ok( $tb->height, 2);
ok( $tb->width, 24);

BEGIN { $n_tests += 4 }
$tb->load( TYP_DATA);
ok( $tb->n_cols, 4);
ok( $tb->height, 6);
ok( $tb->width, 30);
ok( $tb->stringify, TYP_ANS);

BEGIN { $n_tests += 3 }
$tb->clear;
ok( $tb->n_cols, 4);
ok( $tb->height, 2);
ok( $tb->width, 24);

# access parts of table
BEGIN { $n_tests += 8 }
$tb->load( TYP_DATA);

ok( join( '', $tb->title), TYP_TITLE_ANS);
ok( join( '', $tb->body), TYP_BODY_ANS);
my ( $first_title, $last_title) = ( TYP_TITLE_ANS =~ /(.*\n)/g)[ 0, -1];
my ( $first_body, $last_body) = ( TYP_BODY_ANS =~ /(.*\n)/g)[ 0, -1];
ok( ($tb->title( 0))[ 0], $first_title);
ok( ($tb->body( 0))[ 0], $first_body);
ok( ($tb->table( 0))[ 0], $first_title);
ok( ($tb->title( -1))[ 0], $last_title);
ok( ($tb->body( -1))[ 0], $last_body);
ok( ($tb->table( -1))[ 0], $last_body);

### separators and rules
BEGIN { $n_tests += 7 }
$tb = Text::Table->new( 'aaa', \' x ', 'bbb');
ok( $tb->rule,            "    x    \n");
ok( $tb->rule( '='     ), "====x====\n");
ok( $tb->rule( '=', '+'), "====+====\n");

$tb->add( 'tttttt', '');
ok( $tb->rule, "       x    \n");

# multiple separators
$tb = Text::Table->new( 'aaa', \' xxxxx ', \' y ', 'bbb');
ok( $tb->rule, "    y    \n");

# different separators in head and body
$tb = Text::Table->new( 'aaa', \"x\ny", 'bbb');
ok( $tb->rule, "   x   \n");
ok( $tb->body_rule, "   y   \n");

### colrange
BEGIN { $n_tests += 16 }
$tb = Text::Table->new( 'aaa', \"|", 'bbb');
ok( ($tb->colrange( 0))[ 0], 0);
ok( ($tb->colrange( 0))[ 1], 3);
ok( ($tb->colrange( 1))[ 0], 4);
ok( ($tb->colrange( 1))[ 1], 3);
ok( ($tb->colrange( 2))[ 0], 7);
ok( ($tb->colrange( 2))[ 1], 0);
ok( ($tb->colrange( 9))[ 0], 7);
ok( ($tb->colrange( 9))[ 1], 0);
ok( ($tb->colrange( -1))[ 0], 4);
ok( ($tb->colrange( -1))[ 1], 3);

$tb->add( 'xxxxxx', 'yy');
ok( ($tb->colrange( 0))[ 0], 0);
ok( ($tb->colrange( 0))[ 1], 6);
ok( ($tb->colrange( 1))[ 0], 7);
ok( ($tb->colrange( 1))[ 1], 3);
ok( ($tb->colrange( 2))[ 0], 10);
ok( ($tb->colrange( 2))[ 1], 0);

# body-title alignment
BEGIN { $n_tests += 4 }

$tb = Text::Table->new( { title => 'x', align_title => 'right' });
$tb->add( 'xxx');
chomp( $tit = $tb->title( 0));
ok( $tit, '  x');

$tb = Text::Table->new( { title => 'x', align_title => 'center' });
$tb->add( 'xxx');
chomp( $tit = $tb->title( 0));
ok( $tit, ' x ');

$tb = Text::Table->new( { title => 'x', align_title => 'left' });
$tb->add( 'xxx');
chomp( $tit = $tb->title( 0));
ok( $tit, 'x  ');

$tb = Text::Table->new( { title => 'x' }); # default?
$tb->add( 'xxx');
chomp( $tit = $tb->title( 0));
ok( $tit, 'x  ');

# title-internal alignment
BEGIN { $n_tests += 5 }

$tb = Text::Table->new( { title => "x\nxxx", align_title_lines => 'right'});
chomp( ( $tit) = $tb->title); # first line
ok( $tit, '  x');

$tb = Text::Table->new( { title => "x\nxxx", align_title_lines => 'center'});
chomp( ( $tit) = $tb->title); # first line
ok( $tit, ' x ');

$tb = Text::Table->new( { title => "x\nxxx", align_title_lines => 'left'});
chomp( ( $tit) = $tb->title); # first line
ok( $tit, 'x  ');

# default?
$tb = Text::Table->new( { title => "x\nxxx"});
chomp( ( $tit) = $tb->title); # first line
ok( $tit, 'x  ');

# default propagation from 'align_title'
$tb = Text::Table->new( { title => "x\nxxx", align_title => 'right'});
chomp( ( $tit) = $tb->title);
ok( $tit, '  x');

### column selection
BEGIN { $n_tests += 5 }

$tb = Text::Table->new( '', '');
$tb->load( [ 0, 1], [ undef, 2], [ '', 3]);

ok( $tb->select(   0,    1 )->n_cols, 2);
ok( $tb->select( [ 0],   1 )->n_cols, 1);
ok( $tb->select(   0,  [ 1])->n_cols, 2);
ok( $tb->select( [ 0], [ 1])->n_cols, 1);
ok( $tb->select( [ 0,    1])->n_cols, 0);

# multiple selection
BEGIN { $n_tests += 3 }
my $mult = $tb->select( 0, 1, 0, 1);
ok( $mult->n_cols, 4);
ok( $mult->height, 3);
ok( $mult->stringify, <<EOT);
0 1 0 1
  2   2
  3   3
EOT

# overloading
BEGIN { $n_tests += 1 }
$tb = Text::Table->new( TYP_TITLE);
$tb->load( TYP_DATA);
ok( "$tb", TYP_ANS);

# multi-line rows
BEGIN { $n_tests += 1 }
$tb = Text::Table->new( qw( A B C ) );
$tb->load( [ "1", "2", "3" ],
           [ "a\nb", "c", "d" ],
           [ "e", "f\ng", "h" ],
           [ "i", "j", "k\nl" ],
           [ "m", "n", "o" ] );
ok( "$tb", <<EOT);
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
ok( "" . Text::Table
             -> new( TYP_TITLE )
             -> load( TYP_DATA ),
    TYP_ANS );

# Chained ->add call
BEGIN { $n_tests += 1 }
ok( "" . Text::Table
             -> new( "x" x 10 )
             -> add( "y" x 10 ),
    "x" x 10 . "\n" . "y" x 10 . "\n");

BEGIN { plan tests => $n_tests }
