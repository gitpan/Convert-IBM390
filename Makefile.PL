use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Convert::IBM390',
    'VERSION_FROM' => 'IBM390.pm', # finds $VERSION
    'LIBS'	=> ['-lm'],
    'OBJECT'    => 'IBM390.o IBM390lib.o',
    'DEFINE'	=> '',
#    'DEFINE'	=> '-DDEBUG390',    # if debugging is desired
    'INC'	=> '',    # e.g., -I/usr/local/lib/.../CORE
    'dist'	=> { COMPRESS=>'gzip', SUFFIX=>'gz' },
);
