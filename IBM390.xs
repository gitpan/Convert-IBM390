#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "./IBM390lib.h"
#include "./packeb.h"

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = Convert::IBM390		PACKAGE = Convert::IBM390


 # Full Collating Sequence Translate -- like tr///, but assumes that
 # the searchstring is a complete 8-bit collating sequence
 # (x'00' - x'FF').  I couldn't get tr to do this, and I have my
 # doubts about whether it would be possible on systems where char
 # is signed.  This approach works on AIX, where char is unsigned,
 # and at least has a fighting chance of working elsewhere.
 # The second argument is one of the translation tables defined
 # in IBM390.pm ($a2e_table, etc.).
SV *
fcs_xlate(instring, to_table)
	SV *    instring
	char *  to_table
	PROTOTYPE: $$
	PREINIT:
	int  instring_len;
	STRLEN  pv_string_len;
	char *  outstring_wk;
	char *  instring_copy;

	CODE:
#ifdef DEBUG390
	fprintf(stderr, "*D* fcs_xlate: beginning\n");
#endif
	instring_len = (int) SvCUR(instring);
	New(0, outstring_wk, instring_len, char);
	instring_copy = SvPV(instring, pv_string_len);
#ifdef DEBUG390
	fprintf(stderr, "*D* fcs_xlate: input string copied\n");
#endif
	CF_fcs_xlate(outstring_wk, instring_copy, instring_len,
	  to_table);
	RETVAL = newSVpv(outstring_wk, instring_len);
	Safefree(outstring_wk);
#ifdef DEBUG390
	fprintf(stderr, "*D* fcs_xlate: returning\n");
#endif

	OUTPUT:
	RETVAL


 # packeb -- Pack an EBCDIC record
SV *
packeb_XS(template, values_ref, a2e_table)
	char *  template
	SV *    values_ref
	char *  a2e_table
	PROTOTYPE: $$$
	PREINIT:
	AV *    values;
	SV *    outstring;
	 /* The length will be filled in by the C function. */
	STRLEN  outstring_len;

	CODE:
#ifdef DEBUG390
	fprintf(stderr, "*D* packeb_XS: beginning\n");
#endif
	values = (AV *) SvRV(values_ref);
	outstring = newSVpv("", 0);
	CF_packeb(outstring, template, values, a2e_table, &outstring_len);
	RETVAL = outstring;
#ifdef DEBUG390
	fprintf(stderr, "*D* packeb_XS: returning\n");
#endif

	OUTPUT:
	RETVAL


 # unpackeb -- Unpack an EBCDIC record
 # Note that the EBCDIC data may contain nulls and other unprintable
 # stuff, so we need an SV*, not just a char*.
 # The returned values come back as an array of SV*s; we mortalize
 # them and put them on the stack.
void
unpackeb_XS(template, ebrecord, e2a_table)
	char *  template
	SV *    ebrecord
	char *  e2a_table
	PROTOTYPE: $$$
	PREINIT:
	int     nelems, i;
	SV *	ret_svs[4400]; /* The series of returned SV*s */

	PPCODE:
#ifdef DEBUG390
	fprintf(stderr, "*D* unpackeb_XS: beginning\n");
#endif
	nelems = CF_unpackeb(ret_svs, template, ebrecord, e2a_table);
	for (i = 0; i < nelems; i++) {
	   XPUSHs(sv_2mortal(ret_svs[i]));
	}
#ifdef DEBUG390
	fprintf(stderr, "*D* unpackeb_XS: returning %d elements\n",
	  nelems);
#endif
