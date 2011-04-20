# t/01_ini.t; just to load Text::Table by using it

use strict;
use warnings;

$|++; 
print "1..1
";
my($test) = 1;

# 1 load
use Text::Table;
my($loaded) = 1;
$loaded ? print "ok $test
" : print "not ok $test
";
$test++;

# 2 pod syntax
# ugh. can't think of a good way to check for podchecker portably

# my $skip = !( my $podfile = $INC{ 'Text/Table.pm'});
# $skip ||= !( my $podchecker = `which podcheckerX`);
# chomp $podchecker;
# my $podok = `$podchecker $podfile 2>&1` =~ /pod syntax OK/ unless $skip;
# if ( $skip ) {
#     print "ok $test # Skip\n";
# } else {
#     print $podok ? "ok $test\n" : "not ok $test\n";
# }
# $test++;

# end of t/01_ini.t

