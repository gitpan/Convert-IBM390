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


 # Packed Decimal In -- convert a packed field to a Perl number
SV *
pdi(packed_num, ndec=0)
	SV *   packed_num
	int    ndec
	PROTOTYPE: $;$
	PREINIT:
	STRLEN plen;
	char   packed_str[16];
	char  *pv_input;
	int    i, inv_packed;

	CODE:
#ifdef DEBUG390
	fprintf(stderr, "*D* pdi: beginning\n");
#endif
	pv_input = SvPV(packed_num, plen);
	memcpy(packed_str, pv_input, (int) plen);
#ifdef DEBUG390
	fprintf(stderr, "*D* pdi: memcpy succeeded\n");
#endif
	if ( _valid_packed(packed_str, plen) ) {
	   RETVAL = newSVnv( CF_pdi(packed_str, plen, ndec) );
	} else {
	   if ( SvTRUE(perl_get_sv("Convert::IBM390::warninv", FALSE)) )
	      { warn("pdi: Invalid packed field"); }
	   RETVAL = &sv_undef;
	}
#ifdef DEBUG390
	fprintf(stderr, "*D* pdi: returning\n");
#endif

	OUTPUT:
	RETVAL

 # Packed Decimal Out -- convert a Perl number to a packed field
SV *
pdo(perlnum, outbytes=8, ndec=0)
	SV *    perlnum
	int     outbytes
	int     ndec
	PROTOTYPE: $;$$
	PREINIT:
	double  perlnum_d;
	char    packed_wk[16];

	CODE:
#ifdef DEBUG390
	fprintf(stderr, "*D* pdo: beginning\n");
#endif
	if (SvNIOK(perlnum) ) {
	   perlnum_d = SvNV(perlnum);
	   CF_pdo(packed_wk, perlnum_d, outbytes, ndec);
	   RETVAL = newSVpv(packed_wk, outbytes);
	} else {
	   if ( SvTRUE(perl_get_sv("Convert::IBM390::warninv", FALSE)) )
	      { warn("pdo: Input is not a number"); }
	   RETVAL = &sv_undef;
	}
#ifdef DEBUG390
	fprintf(stderr, "*D* pdo: returning\n");
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


 # unpackeb -- Unpack an EBCDIC record
 # Note that the EBCDIC data may contain nulls and other unprintable
 # stuff, so we need an SV*, not just a char*.
AV *
unpackeb_XS(template, ebrecord, e2a_table)
	char *	 template
	SV *     ebrecord
	char *   e2a_table
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
