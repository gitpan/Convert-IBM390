#include <math.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
/*----------------------------------------------------------
  The C functions defined here correspond to the routines
  in IBM390.pm, but are faster than straight Perl code.
----------------------------------------------------------*/


/*---------- Test for a valid packed decimal field ----------*/
int _valid_packed (
  char * packed_str,
  int    plen )
{
 int   i;
 unsigned char pdigits;

#ifdef DEBUG390
  fprintf(stderr, "*D* _valid_packed: beginning\n");
#endif
 for (i = 0; i < plen; i++) {
    pdigits = (unsigned char) packed_str[i];
    if (i < plen - 1) {
       if (((pdigits & 0xF0) > 0x90) || ((pdigits & 0x0F) > 0x09))
          { return 0; }
    } else {
       if (((pdigits & 0xF0) > 0x90) || ((pdigits & 0x0F) < 0x0A))
          { return 0; }
    }
 }

#ifdef DEBUG390
  fprintf(stderr, "*D* _valid_packed: returning 1\n");
#endif
 return 1;
}


/*---------- Packed Decimal In ----------*/
double  CF_pdi
  ( char * packed,
    int    plength,
    int    ndec )
{
 double  out_num;
 short   i;
 unsigned char  pdigits, signum;

#ifdef DEBUG390
  fprintf(stderr, "*D* CF_pdi: beginning\n");
#endif
 out_num = 0.0;
 for (i = 0; i < plength; i++) {
    pdigits = (unsigned char) *(packed + i);
    out_num = (out_num * 10) + (pdigits >> 4);
    if (i < plength - 1)
       out_num = (out_num * 10) + (pdigits & 0x0F);
    else
       signum = pdigits & 0x0F;
 }
 if (signum == 0x0D || signum == 0x0B) {
    out_num = -out_num;
 }

  /* If ndec is 0, we're finished; if it's nonzero,
     correct the number of decimal places. */
 if ( ndec != 0 ) {
    out_num = out_num / pow(10.0, (double) ndec);
 }

#ifdef DEBUG390
  fprintf(stderr, "*D* CF_pdi: returning %f\n", out_num);
#endif
 return out_num;
}


/*---------- Packed Decimal Out ----------*/
void  CF_pdo
  ( char  *packed_ptr,
    double perlnum,
    int    outbytes,
    int    ndec )
{
 int     outdigits, i;
 double  perl_absval;
 char    digits[36];
 char   *digit_ptr, *out_ptr;
 char    signum;

#ifdef DEBUG390
  fprintf(stderr, "*D* CF_pdo: beginning\n");
#endif
 if (perlnum >= 0) {
    perl_absval = perlnum;   signum = 0x0C;
 } else {
    perl_absval = 0 - perlnum;  signum = 0x0D;
 }
   /* sprintf will round to an "integral" value. */
 sprintf(digits, "%031.0f", perl_absval * pow(10.0, (double) ndec));
 outdigits = outbytes * 2 - 1;
 digit_ptr = digits;
 out_ptr = packed_ptr;
 for (i = 31 - outdigits; i < 31; i += 2) {
    if (i < 30) {
       (*out_ptr) = ((*(digit_ptr + i)) << 4) |
          ((*(digit_ptr + i + 1)) & 0x0F) ;
    } else {
       (*out_ptr) = ((*(digit_ptr + i)) << 4) | signum;
    }
    out_ptr++;
 }

#ifdef DEBUG390
  fprintf(stderr, "*D* CF_pdo: returning\n");
#endif
 return;
}


/*---------- Full Collating Sequence Translate ----------*/
void  CF_fcs_xlate
  ( char  *outstring,
    char  *instring,
    int    instring_len,
    char  *to_table )
{
 char  *out_ptr;
 unsigned char offset;
 int    i;

#ifdef DEBUG390
  fprintf(stderr, "*D* CF_fcs_xlate: beginning\n");
#endif
 out_ptr = outstring;
 for (i = 0; i < instring_len; i++) {
    offset = (unsigned char) *(instring + i);
    (*out_ptr) = *(to_table + offset);
    out_ptr++;
 }

#ifdef DEBUG390
  fprintf(stderr, "*D* CF_fcs_xlate: returning\n");
#endif
 return;
}


/*---------- _halfword ----------*/
/* This function returns the value of a Sys/390 halfword (a signed
   16-bit big-endian integer). */
int _halfword (
  char * hw_ptr )
{
  return  (((signed char) hw_ptr[0]) << 8)
        + (unsigned char) hw_ptr[1];
}


/*---------- Unpack an EBCDIC record ----------*/
/* This function, unlike the others, is not pure C; it uses Perl
 * macros, #defines, etc.  Some of this code is shamelessly stolen
 * from the Perl unpack function (pp.c).
 */
void CF_unpackeb (
  AV   * result_array,
  char * pat,
  SV   * ebrecord,
  char * eb_xlate_table )
{
 SV *sv;
 STRLEN rlen;

 register char *s = SvPV(ebrecord, rlen);
 char *strend = s + rlen;
 register char *patend;
 char datumtype;
 register I32 len;
 int i, j, ndec, fieldlen;
 /* The eb_work area keeps us from having to allocate memory
    every time we have a short EBCDIC string to translate.
    If our string is longer than this, we call New. */
 char eb_work[260];
 char *eb_longwork;

 /* Work fields */
 I32 along;
 long long alonglong;
 /* Some day we may want to support S/390 floats.... */
 /*float afloat;*/
 double adouble;

#ifdef DEBUG390
  fprintf(stderr, "*D* CF_unpackeb: beginning\n");
#endif
 patend = pat + strlen(pat);

 while (pat < patend) {
    datumtype = *pat++;
    if (isSPACE(datumtype))
        continue;
    ndec = 0;
    if (pat >= patend) {
        len = 1;
     }
    else if (*pat == '*') {
        len = strend - s;
        if (datumtype == 'i' || datumtype == 'I')  len = len / 4;
        if (datumtype == 's' || datumtype == 'S')  len = len / 2;
        pat++;
    }
    else if (isDIGIT(*pat)) {
        len = *pat++ - '0';
        while (isDIGIT(*pat))
    	len = (len * 10) + (*pat++ - '0');
        /* Decimal places (this result will be ignored if the
           datumtype is not packed). */
        ndec = 0;
        if (*pat == '.') {
           pat++;
           while (isDIGIT(*pat))
              ndec = (ndec * 10) + (*pat++ - '0');
        }
    }
    else {
        len = 1;
    }
    if (len > 32767) {
       croak("Field length too large in unpackeb: %c%d",
          datumtype, len);
    }

#ifdef DEBUG390
    fprintf(stderr, "*D* CF_unpackeb: datumtype/len %c%d\n",
      datumtype, len);
#endif
    switch(datumtype) {
    /* [eE]: EBCDIC character string.  In this case, the length
       given in the template is the length of a single field, not
       a number of repetitions. */
    case 'e':
    case 'E':
        if (len > strend - s)
           len = strend - s;
        if (len <= 260) {
           CF_fcs_xlate(eb_work, s, len, eb_xlate_table);
           sv = newSVpv(eb_work, len);
        } else {
           New(0, eb_longwork, len, char);
           CF_fcs_xlate(eb_longwork, s, len, eb_xlate_table);
           sv = newSVpv(eb_longwork, len);
           Safefree(eb_longwork);
        }
        s += len;
        av_push(result_array, sv);
        break;

    /* p: S/390 packed decimal.  In this case, the length given
       in the template is the length of a single field, not a
       number of repetitions. */
    case 'p':
        if (len > strend - s)
           len = strend - s;
        if (len > 16) {
           croak("Field length too large in unpackeb: p%d", len);
        }
	if ( _valid_packed(s, len) ) {
           adouble = CF_pdi(s, len, ndec);
           sv = newSVnv(adouble);
        } else {
           sv = &sv_undef;
        }

        s += len;
        av_push(result_array, sv);
        break;

    /* [Cc]: characters without translation */
    case 'C':
    case 'c':
        if (len > strend - s)
           len = strend - s;
        sv = newSVpv(s, len);
        s += len;
        av_push(result_array, sv);
        break;

    /* i: integer (System/390 fullword) */
    case 'i':
        if (len > (strend - s) / 4)
           len = (strend - s) / 4;
        for (i=0; i < len; i++) {
           along = 0;
           along = (signed char) *s;  s++;
           for (j=1; j < 4; j++) {
              along <<= 8;
              along += (unsigned char) *s;  s++;
           } 

           sv = newSViv(along);
           av_push(result_array, sv);
        }
        break;

    /* s: short integer (System/390 halfword) */
    case 's':
        if (len > (strend - s) / 2)
           len = (strend - s) / 2;
        for (i=0; i < len; i++) {
           along = _halfword(s);
           s += 2;

           sv = newSViv(along);
           av_push(result_array, sv);
        }
        break;

    /* v: varchar EBCDIC character string; i.e., a string of
       EBCDIC characters preceded by a halfword length field (as
       in DB2/MVS, for instance).  'len' here is a repeat count,
       but don't go beyond the end of the record. */
    case 'v':
        for (i=0; i < len; i++) {
            if (s >= strend)
               break;
            fieldlen = _halfword(s);
            s += 2;

            if (fieldlen > strend - s)
               fieldlen = strend - s;
            if (fieldlen < 0) {
               sv = &sv_undef;
            } else if (fieldlen == 0) {
               sv = newSVpv("", 0);
            } else if (fieldlen <= 260) {
               CF_fcs_xlate(eb_work, s, fieldlen, eb_xlate_table);
               sv = newSVpv(eb_work, fieldlen);
            } else {
               New(0, eb_longwork, fieldlen, char);
               CF_fcs_xlate(eb_longwork, s, fieldlen, eb_xlate_table);
               sv = newSVpv(eb_longwork, fieldlen);
               Safefree(eb_longwork);
            }
            s += fieldlen;
            av_push(result_array, sv);
        }
        break;

    /* x: ignore these bytes (do not return an element) */
    case 'x':
        if (len > strend - s)
           len = strend - s;
        s += len;
        break;

    /* I: unsigned integer (fullword) */
    /* On most systems, integer = long = 32 bits, signed.
       Therefore, to be safe, we compute this as a long long
       and then cast it to a double. */
    case 'I':
        if (len > (strend - s) / 4)
           len = (strend - s) / 4;
        if (sizeof(long long) <= 4) {
           warn("Unsigned integer results may be invalid");
        }
        for (i=0; i < len; i++) {
           alonglong = 0;
           for (j=0; j < 4; j++) {
              alonglong <<= 8;
              alonglong += (unsigned char) *s;  s++;
           }

           sv = newSVnv((double) alonglong);
           av_push(result_array, sv);
        }
        break;

    /* S: unsigned short integer (halfword) */
    case 'S':
        if (len > (strend - s) / 2)
           len = (strend - s) / 2;
        for (i=0; i < len; i++) {
           along = 0;
           along = ((unsigned char) *s) << 8;  s++;
           along += (unsigned char) *s;  s++;

           sv = newSViv(along);
           av_push(result_array, sv);
        }
        break;

    default:
        croak("Invalid type in unpackeb: '%c'", datumtype);
    }
 }

#ifdef DEBUG390
  fprintf(stderr, "*D* CF_unpackeb: returning\n");
#endif
 return;
}
