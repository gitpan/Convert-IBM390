use ExtUtils::MakeMaker;
use Config qw(config_re);

$use_xs = (grep { $_ eq 'noxs' } @ARGV) == 0;

#--- Subroutine to find the internal name of 'undef'.  This is
#--- sv_undef in older releases, PL_sv_undef in more recent releases.
#--- Since many are still using the older releases, we take care of
#--- it here.  In the near future, this can be removed.
sub undef_flag {
 if ($] < 5.005) { return '-DOLD_INTERNAL'; }
 else            { return ''; }
}

if ($use_xs) {
  @perlonly = ();
  print "\n\n","*"x40,"\n";
  print "Using Perl/XS implementation\n";
  print "*"x40,"\n\n";
  $infile = 'IBM390_pm_xsver';
  $outfile = 'IBM390.pm';
} else {
  @perlonly = (
    XS => {},
    C => []
  );
  print "\n\n","*"x40,"\n";
  print "Using Perl-only implementation\n";
  print "*"x40,"\n\n";
  $infile = 'IBM390_pm_perlver';
  $outfile = 'IBM390.pm';
}

open(IN, "d/$infile") or die "Cannot open d/$infile: $!";
open(OUT,">$outfile") or die "Cannot open $outfile: $!";
while(<IN>) {
   print OUT;
}
close(IN);
close(OUT);

#--- Linux has putenv, but it causes a memory leak, so setenv is
#--- better. Many systems, however, don't have setenv (e.g. AIX), so
#--- we have to define this variable ... ugh.
$os = (config_re('osname'))[0];
if ($os =~ /linux|cygwin/i) {
   $p_define = '-DHAVE_SETENV';
} else {
   $p_define = '';
}

#--- C code

if ($use_xs) {
  @c_code = qw(IBM390lib.ccc IBM390lib.hhh);
  foreach $file (@c_code) {
    ($outfile = $file) =~ s/(ccc|hhh)/substr($1,0,1)/e;
    open(IN, "d/$file") or die "Cannot open d/$infile: $!";
    open(OUT,">$outfile") or die "Cannot open $outfile: $!";
    while(<IN>) { print OUT; }
    close(IN);
    close(OUT);
  }
  $p_define .= undef_flag();
}

#--- WriteMakefile parameters
$p_obj = '$(O_FILES)' x $use_xs;

WriteMakefile(
    'NAME'	=> 'Convert::IBM390',
    'VERSION_FROM' => 'IBM390.pm', # finds $VERSION
    'OBJECT'    => $p_obj,
    'DEFINE'	=> $p_define,
#    'DEFINE'	=> "$p_define -DDEBUG390",   # if debugging is desired
    'INC'	=> '',    # e.g., -I/usr/local/lib/.../CORE
    'clean'	=> { FILES => 'IBM390.pm IBM390lib.c IBM390lib.h ' },
    'dist'	=> { PREOP => 'cp -p d/IBM390_pm_dummy IBM390.pm' },
    @perlonly,
);
