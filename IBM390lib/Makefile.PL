use ExtUtils::MakeMaker;
$Verbose = 1;
WriteMakefile(
  NAME    => 'Convert::IBM390::IBM390lib',
  SKIP    => [qw(all static static_lib dynamic dynamic_lib)],
  clean   => {'FILES' => 'libIBM390lib$(LIB_EXT)'},
);

sub MY::top_targets {
	'
all :: static

pure_all :: static

static :: libIBM390lib$(LIB_EXT)

libIBM390lib$(LIB_EXT): $(O_FILES)
	$(AR) cr libIBM390lib$(LIB_EXT) $(O_FILES)
	$(RANLIB) libIBM390lib$(LIB_EXT)

';
}
