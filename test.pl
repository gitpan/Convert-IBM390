# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

################## We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..16\n"; }
END {print "not ok 1\n" unless $loaded;}
use Convert::IBM390 qw(:all);
$loaded = 1;
print "ok 1\n";

################## End of black magic.

my $failed = 0;
#----- asc2eb
print "asc2eb...........";
my ($asc, $eb);
$asc = ".<(+|!\$*%\@=[]A2";
$eb = asc2eb($asc);
was_it_ok(2, $eb eq "KLMNOZ[\\l|~\xAD\xBD\xC1\xF2");

#----- eb2asc
print "eb2asc...........";
$eb = "KLMNOZ[\\l|~\xAD\xBD\xC1\xF2";
$asc = eb2asc($eb);
was_it_ok(3, $asc eq ".<(+|!\$*%\@=[]A2");

#----- eb2ascp
print "eb2ascp..........";
$eb = "KLMNOZ[\\l|~\xAD\xBD\xC1\xF2\x00\xFE";
$asc = eb2ascp($eb);
was_it_ok(4, $asc eq ".<(+|!\$*%\@=[]A2  ");

#----- hexdump
print "hexdump..........";
my ($string, @hdump);
$string = "Now is the time for all good Perls to come to the aid of
their systems";
@hdump = hexdump($string, 4);
was_it_ok(5, (@hdump == 3) && $hdump[0] eq 
  "000004: 4E6F7720 69732074 68652074 696D6520  666F7220 616C6C20 676F6F64 20506572  *Now is the time for all good Per*\n");

#----- packed2num
print "packed2num.......";
my (@pd, @perlnum);
@pd = (pack("H4", "012C"), pack("H2", "0C"), pack("H6", "00789D"));
@perlnum = (packed2num($pd[0]), packed2num($pd[1]), packed2num($pd[2], 2));
was_it_ok(6, $perlnum[0] == 12 &&
    $perlnum[1] == 0 &&
    $perlnum[2] == -7.89);

#----- packed2num with undefined result
print "          .......";
my $perlnum = packed2num(pack("H4", "0D07"));
was_it_ok(7, ! defined($perlnum));

#----- num2packed
print "num2packed.......";
@perlnum = (5.67, 0, -987);
@pd = (num2packed($perlnum[0], 3,2), num2packed($perlnum[1],3), num2packed($perlnum[2],3));
was_it_ok(8, $pd[0] eq "\x00\x56\x7C" &&
    $pd[1] eq "\x00\x00\x0C" &&
    $pd[2] eq "\x00\x98\x7D");

#----- num2packed with undefined result
print "          .......";
my $pd = num2packed("notanumber");
was_it_ok(9, ! defined($pd));

#----- zoned2num
print "zoned2num........";
@pd = (pack("H8", "F0F1F2C3"), pack("H2", "C0"), pack("H6", "F7F8D9"));
@perlnum = (zoned2num($pd[0]), zoned2num($pd[1]), zoned2num($pd[2], 2));
was_it_ok(10, $perlnum[0] == 123 &&
    $perlnum[1] == 0 &&
    $perlnum[2] == -7.89);

#----- zoned2num with undefined result
print "         ........";
$perlnum = zoned2num(pack("H4", "0D55"));
was_it_ok(11, ! defined($perlnum));

#----- num2zoned
print "num2zoned........";
@perlnum = (5.67, 0, -987);
@pd = (num2zoned($perlnum[0], 4,2), num2zoned($perlnum[1],3), num2zoned($perlnum[2],3));
was_it_ok(12, $pd[0] eq "\xF0\xF5\xF6\xC7" &&
    $pd[1] eq "\xF0\xF0\xC0" &&
    $pd[2] eq "\xF9\xF8\xD7");

#----- num2zoned with undefined result
print "         ........";
$pd = num2zoned("notanumber");
was_it_ok(13, ! defined($pd));

#----- packeb
print "packeb...........";
open(PT, "./packtests")  or die "test.pl: could not open packtests: $!";
chomp ($ptempl = <PT>);
chomp ($in = <PT>); @input = split(' ', $in);
chomp ($hexes = <PT>);
close PT;
$expected = pack("H*", $hexes);
$ebrecord = packeb($ptempl, @input);
was_it_ok(14, $ebrecord eq $expected);

#----- unpackeb
print "unpackeb.........";
open(UT, "./unptests")  or die "test.pl: could not open unptests: $!";
chomp ($utempl = <UT>);
chomp ($hexes = <UT>);
chomp ($expected = <UT>);
close UT;
$ebrecord = pack("H*", $hexes);
@unp = unpackeb($utempl, $ebrecord);
was_it_ok(15, "<@unp>" eq "<$expected>");

#----- unpackeb with undefined results
print "        .........";
$ebrecord = pack("H12", "C500FFFEC1C2");
($pp, $vv) = unpackeb("p2v", $ebrecord);
was_it_ok(16, !defined($pp) && !defined($vv));

if ($failed == 0) { print "All tests successful.\n"; }
else {
   $tt = ($failed == 1) ? "1 test" : "$failed tests";
   print "$tt failed!  There is no joy in Mudville.\n";
}


sub was_it_ok {
 my ($num, $test) = @_;
 if ($test) { print "ok $num\n"; }
 else       { print "not ok $num\n"; $failed++; }
}
