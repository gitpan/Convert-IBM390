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


 # Convert a packed field to a Perl number
SV *
packed2num(packed_num, ndec=0)
	SV *   packed_num
	int    ndec
	PROTOTYPE: $;$
	PREINIT:
	STRLEN plen;
	char   packed_str[16];
	char  *pv_input;

	CODE:
#ifdef DEBUG390
	fprintf(stderr, "*D* packed2num: beginning\n");
#endif
	pv_input = SvPV(packed_num, plen);
	memcpy(packed_str, pv_input, (int) plen);
#ifdef DEBUG390
	fprintf(stderr, "*D* packed2num: memcpy succeeded\n");
#endif
	if ( _valid_packed(packed_str, plen) ) {
	   RETVAL = newSVnv( CF_packed2num(packed_str, plen, ndec) );
	} else {
	   if ( SvTRUE(perl_get_sv("Convert::IBM390::warninv", FALSE)) )
	      { warn("packed2num: Invalid packed field"); }
	   RETVAL = &sv_undef;
	}
#ifdef DEBUG390
	fprintf(stderr, "*D* packed2num: returning\n");
#endif

	OUTPUT:
	RETVAL

 # Convert a Perl number to a packed field
SV *
num2packed(perlnum, outbytes=8, ndec=0)
	SV *    perlnum
	int     outbytes
	int     ndec
	PROTOTYPE: $;$$
	PREINIT:
	double  perlnum_d;
	char    packed_wk[16];

	CODE:
#ifdef DEBUG390
	fprintf(stderr, "*D* num2packed: beginning\n");
#endif
	if (SvNIOK(perlnum) ) {
	   perlnum_d = SvNV(perlnum);
	   CF_num2packed(packed_wk, perlnum_d, outbytes, ndec);
	   RETVAL = newSVpv(packed_wk, outbytes);
	} else {
	   if ( SvTRUE(perl_get_sv("Convert::IBM390::warninv", FALSE)) )
	      { warn("num2packed: Input is not a number"); }
	   RETVAL = &sv_undef;
	}
#ifdef DEBUG390
	fprintf(stderr, "*D* num2packed: returning\n");
#endif

	OUTPUT:
	RETVAL


 # Convert a zoned field to a Perl number
SV *
zoned2num(zoned_num, ndec=0)
	SV *   zoned_num
	int    ndec
	PROTOTYPE: $;$
	PREINIT:
	STRLEN zlen;
	char   zoned_str[32];
	char  *pv_input;

	CODE:
#ifdef DEBUG390
	fprintf(stderr, "*D* zoned2num: beginning\n");
#endif
	pv_input = SvPV(zoned_num, zlen);
	memcpy(zoned_str, pv_input, (int) zlen);
#ifdef DEBUG390
	fprintf(stderr, "*D* zoned2num: memcpy succeeded\n");
#endif
	if ( _valid_zoned(zoned_str, zlen) ) {
	   RETVAL = newSVnv( CF_zoned2num(zoned_str, zlen, ndec) );
	} else {
	   if ( SvTRUE(perl_get_sv("Convert::IBM390::warninv", FALSE)) )
	      { warn("zoned2num: Invalid zoned field"); }
	   RETVAL = &sv_undef;
	}
#ifdef DEBUG390
	fprintf(stderr, "*D* zoned2num: returning\n");
#endif

	OUTPUT:
	RETVAL

 # Convert a Perl number to a zoned field
SV *
num2zoned(perlnum, outbytes=8, ndec=0)
	SV *    perlnum
	int     outbytes
	int     ndec
	PROTOTYPE: $;$$
	PREINIT:
	double  perlnum_d;
	char    zoned_wk[32];

	CODE:
#ifdef DEBUG390
	fprintf(stderr, "*D* num2zoned: beginning\n");
#endif
	if (SvNIOK(perlnum) ) {
	   perlnum_d = SvNV(perlnum);
	   CF_num2zoned(zoned_wk, perlnum_d, outbytes, ndec);
	   RETVAL = newSVpv(zoned_wk, outbytes);
	} else {
	   if ( SvTRUE(perl_get_sv("Convert::IBM390::warninv", FALSE)) )
	      { warn("num2zoned: Input is not a number"); }
	   RETVAL = &sv_undef;
	}
#ifdef DEBUG390
	fprintf(stderr, "*D* num2zoned: returning\n");
#endif

	OUTPUT:
	RETVAL


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
AV *
unpackeb_XS(template, ebrecord, e2a_table)
	char *  template
	SV *    ebrecord
	char *  e2a_table
	PROTOTYPE: $$$
	PREINIT:

	CODE:
#ifdef DEBUG390
	fprintf(stderr, "*D* unpackeb_XS: beginning\n");
#endif
	RETVAL = newAV();
	CF_unpackeb(RETVAL, template, ebrecord, e2a_table);
#ifdef DEBUG390
	fprintf(stderr, "*D* unpackeb_XS: returning\n");
#endif

	OUTPUT:
	RETVAL
