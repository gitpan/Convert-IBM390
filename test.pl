# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'.

################## We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..8\n"; }
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

#----- packeb
print "packeb...........";
open(PT, "./packtests")  or die "test.pl: could not open packtests: $!";
chomp ($ptempl = <PT>);
chomp ($in = <PT>); @input = split(' ', $in);
chomp ($hexes = <PT>);
close PT;
$expected = pack("H*", $hexes);
$ebrecord = packeb($ptempl, @input);
$zz=packeb("c5C5", 'ab', 'gh');
was_it_ok(6, $ebrecord eq $expected);

#----- unpackeb
print "unpackeb.........";
open(UT, "./unptests")  or die "test.pl: could not open unptests: $!";
chomp ($utempl = <UT>);
chomp ($hexes = <UT>);
chomp ($expected = <UT>);
close UT;
$ebrecord = pack("H*", $hexes);
@unp = unpackeb($utempl, $ebrecord);
was_it_ok(7, "<@unp>" eq "<$expected>");

#----- unpackeb with undefined results
print "        .........";
$ebrecord = pack("H12", "C500FFFEC1C2");
($pp, $vv) = unpackeb("p2v", $ebrecord);
was_it_ok(8, !defined($pp) && !defined($vv));

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
