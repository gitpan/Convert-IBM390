use ExtUtils::MakeMaker;

$use_xs = (grep { $_ eq 'noxs' } @ARGV) == 0;

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

#--- C code

if ($use_xs) {
  @c_code = qw(IBM390lib.ccc IBM390lib.hhh packeb.ccc packeb.hhh);
  foreach $file (@c_code) {
    ($outfile = $file) =~ s/(ccc|hhh)/substr($1,0,1)/e;
    open(IN, "d/$file") or die "Cannot open d/$infile: $!";
    open(OUT,">$outfile") or die "Cannot open $outfile: $!";
    while(<IN>) { print OUT; }
    close(IN);
    close(OUT);
  }
}

#--- WriteMakefile parameters
$p_libs = '-lm' x $use_xs;
$p_obj = '$(O_FILES)' x $use_xs;

WriteMakefile(
    'NAME'	=> 'Convert::IBM390',
    'VERSION_FROM' => 'IBM390.pm', # finds $VERSION
    'LIBS'	=> [$p_libs],
    'OBJECT'    => $p_obj,
    'DEFINE'	=> '',
#    'DEFINE'	=> '-DDEBUG390',    # if debugging is desired
    'INC'	=> '',    # e.g., -I/usr/local/lib/.../CORE
    'clean'	=> { FILES => 'IBM390.pm IBM390lib.c IBM390lib.h '.
	'packeb.c packeb.h' },
    'dist'	=> { COMPRESS=>'gzip' },
    @perlonly,
);
