#include <math.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "./IBM390lib.h"
/*-------------------------------------------------------------------
  Module:  Convert::IBM390
  Functions:  unpackeb, packeb
  These functions are not pure C; they use Perl macros, #defines, etc.
  Some of this code is shamelessly stolen from Perl's built-in
  pack and unpack functions (pp.c).
-------------------------------------------------------------------*/


/* Convert an integer to a System/390 fullword. */
void _to_S390fw (
  char * out_word,
  long   n )
{
 int  i, j, is_little;
 /* The following union is used to see whether the run-time machine
    is little- or big-endian. */
 union {
   short tshort;
   char  tchar[2];
 } t_union;
 /* And this one, for the actual conversion. */
 union {
   long  clong;
   char  cchar[4];
 } c_union;

 /* Little or big? */
 t_union.tshort = 259;  /* In big-endian, x'0103' */
 is_little = (t_union.tchar[0] == 0x03) ? 1 : 0;

 c_union.clong = n;
 if (is_little) {
    for (i=0, j=3; i < 4; i++, j--) {
       (*(out_word+i)) = c_union.cchar[j];
    }
 } else {
    memcpy(out_word, c_union.cchar, 4);
 }
 return;
}


/* Convert an integer to a System/390 halfword. */
void _to_S390hw (
  char * out_word,
  long   n )
{
 int  i, j, is_little;
 /* The following union is used to see whether the run-time machine
    is little- or big-endian. */
 union {
   short tshort;
   char  tchar[2];
 } t_union;
 /* And this one, for the actual conversion. */
 union {
   long  clong;
   char  cchar[4];
 } c_union;

 /* Little or big? */
 t_union.tshort = 259;  /* In big-endian, x'0103' */
 is_little = (t_union.tchar[0] == 0x03) ? 1 : 0;

 c_union.clong = n;
 if (is_little) {
    for (i=0, j=1; i < 2; i++, j--) {
       (*(out_word+i)) = c_union.cchar[j];
    }
 } else {
    memcpy(out_word, c_union.cchar+2, 2);
 }
 return;
}


/*---------- Pack an EBCDIC record ----------*/
void CF_packeb (
  SV   * outstring,
  char * pat,
  AV   * fields_array,
  char * eb_xlate_table,
  STRLEN * outlen_ptr )
{
 SV *   item;
 char * item_data;
 STRLEN item_len;
 int    ii, max_index;  /* ii = item index */
 char   datumtype;
 register char * patend;
 register int len;
 int    j, ndec;

 static char   null10[] = {0,0,0,0,0,0,0,0,0,0};
  /* space10 = native spaces.  espace10 = EBCDIC spaces. */
 static char  space10[] = "          ";
 static char espace10[] =
  { 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40 };

 char achar;
 I16 ashort;
 int aint;
 unsigned int auint;
 I32 along;
 U32 aulong;
 char *aptr;
 double adouble;
 /* The eb_work area is long, but what the heck?  Memory is cheap. */
 char eb_work[32800];

#ifdef DEBUG390
  fprintf(stderr, "*D* CF_packeb: beginning\n");
#endif
 max_index = av_len(fields_array);
 ii = 0;
 patend = pat + strlen(pat);

 while (pat < patend) {
 /* Have we gone past the end of the list of values?  If so, stop. */
    if (ii > max_index)
       break;

    datumtype = *pat++;
    if (isSPACE(datumtype))
       continue;
    if (*pat == '*') {
       len = strchr("pz", datumtype) ? 8 : 
         (strchr("@x", datumtype) ? 0 : max_index - ii + 1);
       pat++;
    } else if (isDIGIT(*pat)) {
        len = *pat++ - '0';
        while (isDIGIT(*pat))
           len = (len * 10) + (*pat++ - '0');
        /* Decimal places (this result will be ignored if the
           datumtype is not packed or zoned). */
        ndec = 0;
        if (*pat == '.') {
           pat++;
           while (isDIGIT(*pat))
              ndec = (ndec * 10) + (*pat++ - '0');
        }
    } else {
       len = strchr("pz", datumtype) ? 8 : 1;
    }

    if (len > 32767) {
       croak("Field length too large in packeb: %c%d",
          datumtype, len);
    }
#ifdef DEBUG390
    fprintf(stderr, "*D* CF_packeb: datumtype/len %c%d\n",
      datumtype, len);
#endif

    switch(datumtype) {
      case '@':
          len -= SvCUR(outstring);
          if (len > 0)
             goto grow;
          len = -len;
          if (len > 0)
             goto shrink;
          break;
        shrink:
          if (SvCUR(outstring) < len)
             croak("@ position outside string");
          SvCUR(outstring) -= len;
          *SvEND(outstring) = '\0';
          break;
      case 'x':
        grow:
          while (len >= 10) {
             sv_catpvn(outstring, null10, 10);
             len -= 10;
          }
          sv_catpvn(outstring, null10, len);
          break;

      /* [Ee]:  EBCDIC character string */
      case 'E':
      case 'e':
          item = *(av_fetch(fields_array, ii, 0));
          ii++;
          aptr = SvPV(item, item_len);
          if (pat[-1] == '*')
              len = item_len;
          CF_fcs_xlate(eb_work, aptr, len, eb_xlate_table);

          if (item_len > len)
              sv_catpvn(outstring, eb_work, len);
          else {
              sv_catpvn(outstring, eb_work, item_len);
              len -= item_len;
              if (datumtype == 'E') {
                  while (len >= 10) {
                      sv_catpvn(outstring, espace10, 10);
                      len -= 10;
                  }
                  sv_catpvn(outstring, espace10, len);
              }
              else {
                  while (len >= 10) {
                      sv_catpvn(outstring, null10, 10);
                      len -= 10;
                  }
                  sv_catpvn(outstring, null10, len);
              }
          }
          break;

      /* [Cc]: characters without translation.  If space padding
         is requested, we pad with native spaces, not x'40'. */
      case 'C':
      case 'c':
          item = *(av_fetch(fields_array, ii, 0));
          ii++;
          aptr = SvPV(item, item_len);
          if (pat[-1] == '*')
              len = item_len;
          if (item_len > len)
              sv_catpvn(outstring, aptr, len);
          else {
              sv_catpvn(outstring, aptr, item_len);
              len -= item_len;
              if (datumtype == 'C') {
                  while (len >= 10) {
                      sv_catpvn(outstring, space10, 10);
                      len -= 10;
                  }
                  sv_catpvn(outstring, space10, len);
              }
              else {
                  while (len >= 10) {
                      sv_catpvn(outstring, null10, 10);
                      len -= 10;
                  }
                  sv_catpvn(outstring, null10, len);
              }
          }
          break;

      /* p: S/390 packed decimal.  In this case, the length given
         in the template is the length of a single field, not a
         number of repetitions. */
      case 'p':
          if (len > 16) {
             croak("Field length too large in packeb: p%d", len);
          }
          item = *(av_fetch(fields_array, ii, 0));
          ii++;
          adouble = SvNV(item);

          CF_num2packed(eb_work, adouble, len, ndec);
          sv_catpvn(outstring, eb_work, len);
          break;

      /* i: S/390 fullword (signed). */
      case 'i':
          for (j = 0; j < len; j++) {
             item = *(av_fetch(fields_array, ii, 0));
             ii++;
             along = SvIV(item);
             _to_S390fw(eb_work, along);
             sv_catpvn(outstring, eb_work, 4);
          }
          break;

      /* [sS]: S/390 halfword (signed/unsigned). */
      case 's':
      case 'S':
          for (j = 0; j < len; j++) {
             item = *(av_fetch(fields_array, ii, 0));
             ii++;
             along = SvIV(item);
             if (datumtype == 's') {
                _to_S390hw(eb_work, along);
                sv_catpvn(outstring, eb_work, 2);
             } else {
                _to_S390fw(eb_work, along);
                sv_catpvn(outstring, eb_work+2, 2);
             }
          }
          break;

      /* z: S/390 zoned decimal.  In this case, the length given
         in the template is the length of a single field, not a
         number of repetitions. */
      case 'z':
          if (len > 32) {
             croak("Field length too large in packeb: z%d", len);
          }
          item = *(av_fetch(fields_array, ii, 0));
          ii++;
          adouble = SvNV(item);

          CF_num2zoned(eb_work, adouble, len, ndec);
          sv_catpvn(outstring, eb_work, len);
          break;

      case 'H':
      case 'h':
          {
              char *savepat = pat;
              I32 workbyte;

              item = *(av_fetch(fields_array, ii, 0));
              ii++;
              aptr = SvPV(item, item_len);
              if (pat[-1] == '*')
                  len = item_len;
              if (len < 2)
                  len = 2;
              pat = aptr;
              aint = SvCUR(outstring);
              SvCUR(outstring) += (len+1)/2;
              SvGROW(outstring, SvCUR(outstring) + 1);
              aptr = SvPVX(outstring) + aint;
              if (len > item_len)
                  len = item_len;
              aint = len;
              workbyte = 0;
              for (len = 0; len++ < aint;) {
                  if (isALPHA(*pat))
                      workbyte |= ((*pat++ & 15) + 9) & 15;
                  else
                      workbyte |= *pat++ & 15;
                  if (len & 1)
                      workbyte <<= 4;
                  else {
                      *aptr++ = workbyte & 0xff;
                      workbyte = 0;
                  }
              }
              if (aint & 1)
                  *aptr++ = workbyte & 0xff;
              pat = SvPVX(outstring) + SvCUR(outstring);
              while (aptr <= pat)
                  *aptr++ = '\0';

              pat = savepat;
          }
          break;
      default:
         croak("Invalid type in packeb: '%c'", datumtype);
    }
 }
#ifdef DEBUG390
  fprintf(stderr, "*D* CF_packeb: returning\n");
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

 /* Work fields */
 I32 along;
 long long alonglong;
 /* Some day we may want to support S/390 floats.... */
 /*float afloat;*/
 double adouble;
 /* The eb_work area is long, but what the heck?  Memory is cheap. */
 char eb_work[32800];

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
           datumtype is not packed or zoned). */
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
        CF_fcs_xlate(eb_work, s, len, eb_xlate_table);
        sv = newSVpv(eb_work, len);
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
           adouble = CF_packed2num(s, len, ndec);
           sv = newSVnv(adouble);
        } else {
           sv = &sv_undef;
        }

        s += len;
        av_push(result_array, sv);
        break;

    /* z: S/390 zoned decimal.  In this case, the length given
       in the template is the length of a single field, not a
       number of repetitions. */
    case 'z':
        if (len > strend - s)
           len = strend - s;
        if (len > 32) {
           croak("Field length too large in unpackeb: z%d", len);
        }
	if ( _valid_zoned(s, len) ) {
           adouble = CF_zoned2num(s, len, ndec);
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
            } else {
               CF_fcs_xlate(eb_work, s, fieldlen, eb_xlate_table);
               sv = newSVpv(eb_work, fieldlen);
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
