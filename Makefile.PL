use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Convert::IBM390',
    'VERSION_FROM' => 'IBM390.pm', # finds $VERSION
    'LIBS'	=> ['-lm'],
    'OBJECT'    => 'IBM390.o IBM390lib.o',
    'DEFINE'	=> '',    # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',    # e.g., -I/cdwh/perl5/lib/5.00502/aix/CORE',
);
