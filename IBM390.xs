#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "./IBM390lib/IBM390lib.h"

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
	unsigned char  packed_str[16];
	char  *pv_input;
	int    i, inv_packed;

	CODE:
	pv_input = SvPV(packed_num, plen);
	memcpy(packed_str, pv_input, (int) plen);
	  /* Check packed field for validity. */
	inv_packed = 0;
	for (i = 0; i < plen; i++) {
	   if (i < plen - 1) {
	      inv_packed += ((packed_str[i] & 0xF0) > 0x90) ||
	        ((packed_str[i] & 0x0F) > 0x09);
	   } else {
	      inv_packed += ((packed_str[i] & 0xF0) > 0x90) ||
	        ((packed_str[i] & 0x0F) < 0x0A);
	   }
	}
	if (inv_packed) {
	   if ( SvTRUE(perl_get_sv("IBM390::warninv", FALSE)) )
	      { warn("pdi: Invalid packed field"); }
	   RETVAL = &sv_undef;
	} else {
	   RETVAL = newSVnv( CFUNC_pdi(packed_str, plen, ndec) );
	}

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
	unsigned char    packed_wk[16];

	CODE:
	if (SvNIOK(perlnum) ) {
	   perlnum_d = SvNV(perlnum);
	   CFUNC_pdo(packed_wk, perlnum_d, outbytes, ndec);
	   RETVAL = newSVpv((char *)packed_wk, outbytes);
	} else {
	   if ( SvTRUE(perl_get_sv("IBM390::warninv", FALSE)) )
	      { warn("pdo: Input is not a number"); }
	   RETVAL = &sv_undef;
	}

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
	unsigned char *  outstring_wk;
	unsigned char *  instring_copy;

	CODE:
	instring_len = (int) SvCUR(instring);
	New(0, outstring_wk, instring_len, unsigned char);
	instring_copy = SvPV(instring, pv_string_len);
	CFUNC_fcs_xlate(outstring_wk, instring_copy, instring_len,
	  (unsigned char *)to_table);
	RETVAL = newSVpv(outstring_wk, instring_len);
	Safefree(outstring_wk);

	OUTPUT:
	RETVAL
