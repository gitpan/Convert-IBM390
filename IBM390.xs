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

#ifdef OLD_INTERNAL
   #define UNDEF_PTR &sv_undef
#else
   #define UNDEF_PTR &PL_sv_undef
#endif

 /* 36KB may seem small, but on MVS most records are 32KB or less. */
#define OUTSTRING_MEM 36864
 /* Macro: catenate a string to the end of an existing string
  * and move the pointer up. */
#define memcat(target,offset,source,len) \
	memcpy((target+offset), source, len); \
	offset += len;

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


void
asc2eb(instring_sv)
	SV *  instring_sv
	PROTOTYPE: $
	PREINIT:
	STRLEN  ilength;
	char *  instring;
	char *  outstring_wk;
	 /* To avoid allocating small amounts of storage: */
	char    shorty[1024];

	PPCODE:
	instring = SvPV(instring_sv, ilength);
#ifdef DEBUG390
	fprintf(stderr, "*D* asc2eb: beginning; length %d\n", ilength);
#endif
	if (ilength <= 1024) {
	   CF_fcs_xlate(shorty, instring, ilength, a2e_table);
	   PUSHs(sv_2mortal(newSVpvn(shorty, ilength)));
	} else {
	   New(0, outstring_wk, ilength, char);
	   CF_fcs_xlate(outstring_wk, instring, ilength, a2e_table);
	   PUSHs(sv_2mortal(newSVpvn(outstring_wk, ilength)));
	   Safefree(outstring_wk);
	}
#ifdef DEBUG390
	fprintf(stderr, "*D* asc2eb: returning\n");
#endif

void
eb2asc(instring_sv)
	SV *  instring_sv
	PROTOTYPE: $
	PREINIT:
	STRLEN  ilength;
	char *  instring;
	char *  outstring_wk;
	 /* To avoid allocating small amounts of storage: */
	char    shorty[1024];

	PPCODE:
	instring = SvPV(instring_sv, ilength);
#ifdef DEBUG390
	fprintf(stderr, "*D* eb2asc: beginning; length %d\n", ilength);
#endif
	if (ilength <= 1024) {
	   CF_fcs_xlate(shorty, instring, ilength, e2a_table);
	   PUSHs(sv_2mortal(newSVpvn(shorty, ilength)));
	} else {
	   New(0, outstring_wk, ilength, char);
	   CF_fcs_xlate(outstring_wk, instring, ilength, e2a_table);
	   PUSHs(sv_2mortal(newSVpvn(outstring_wk, ilength)));
	   Safefree(outstring_wk);
	}
#ifdef DEBUG390
	fprintf(stderr, "*D* eb2asc: returning\n");
#endif

void
eb2ascp(instring_sv)
	SV *  instring_sv
	PROTOTYPE: $
	PREINIT:
	STRLEN  ilength;
	char *  instring;
	char *  outstring_wk;
	 /* To avoid allocating small amounts of storage: */
	char    shorty[1024];

	PPCODE:
	instring = SvPV(instring_sv, ilength);
#ifdef DEBUG390
	fprintf(stderr, "*D* eb2ascp: beginning; length %d\n", ilength);
#endif
	if (ilength <= 1024) {
	   CF_fcs_xlate(shorty, instring, ilength, e2ap_table);
	   PUSHs(sv_2mortal(newSVpvn(shorty, ilength)));
	} else {
	   New(0, outstring_wk, ilength, char);
	   CF_fcs_xlate(outstring_wk, instring, ilength, e2ap_table);
	   PUSHs(sv_2mortal(newSVpvn(outstring_wk, ilength)));
	   Safefree(outstring_wk);
	}
#ifdef DEBUG390
	fprintf(stderr, "*D* eb2ascp: returning\n");
#endif


 # Much of the following code is shamelessly stolen from Perl's
 # built-in pack and unpack functions (pp.c).
 # packeb -- Pack a list of values into an EBCDIC record
void
packeb(pat, ...)
	char *  pat
	PREINIT:
	char    outstring[OUTSTRING_MEM];

	SV *   item;
	STRLEN item_len;
	int    ii;  /* ii = item index */
	int    oi;  /* oi = outstring index */
	char   datumtype;
	register char * patend;
	register int len;
	int    j, ndec;

	static char   null10[] = {0,0,0,0,0,0,0,0,0,0};
	 /* space10 = native spaces.  espace10 = EBCDIC spaces. */
	static char  space10[] = "          ";
	static char espace10[] =
	 { 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40 };

	I32 along;
	char *aptr;
	double adouble;
	/* The eb_work area is long, but what the heck?  Memory is cheap. */
	char eb_work[32800];

	PPCODE:
#ifdef DEBUG390
	fprintf(stderr, "*D* packeb: beginning\n");
#endif
	ii = 1;
	oi = 0;
	patend = pat + strlen(pat);

	while (pat < patend) {
	/* Have we gone past the end of the list of values?  If so, stop. */
	   if (ii >= items)
	      break;
	   if (oi >= OUTSTRING_MEM)
	      croak("Output structure too large in packeb");

	   datumtype = *pat++;
	   if (isSPACE(datumtype))
	      continue;
	   if (*pat == '*') {
	      len = strchr("pz", datumtype) ? 8 : 
	        (strchr("@x", datumtype) ? 0 : items - ii + 1);
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
	   fprintf(stderr, "*D* packeb: datumtype/len %c%d\n",
	     datumtype, len);
#endif

	   switch(datumtype) {
	     case '@':
	         if (len > OUTSTRING_MEM || len < 0) 
	            croak("@ position outside string");
	         oi = len;
	         break;
	     case 'x':
	         while (len >= 10) {
	            memcat(outstring, oi, null10, 10);
	            len -= 10;
	         }
	         memcat(outstring, oi, null10, len);
	         break;

	     /* [Ee]:  EBCDIC character string */
	     case 'E':
	     case 'e':
	         item = ST(ii);
	         ii++;
	         aptr = SvPV(item, item_len);
	         if (pat[-1] == '*')
	             len = item_len;
	         CF_fcs_xlate(eb_work, aptr, len, a2e_table);

	         if (item_len > len) {
	             memcat(outstring, oi, eb_work, len);
	         } else {
	             memcat(outstring, oi, eb_work, item_len);
	             len -= item_len;
	             if (datumtype == 'E') {
	                 while (len >= 10) {
	                     memcat(outstring, oi, espace10, 10);
	                     len -= 10;
	                 }
	                 memcat(outstring, oi, espace10, len);
	             }
	             else {
	                 while (len >= 10) {
	                     memcat(outstring, oi, null10, 10);
	                     len -= 10;
	                 }
	                 memcat(outstring, oi, null10, len);
	             }
	         }
	         break;

	     /* [Cc]: characters without translation.  If space padding
	        is requested, we pad with native spaces, not x'40'. */
	     case 'C':
	     case 'c':
	         item = ST(ii);
	         ii++;
	         aptr = SvPV(item, item_len);
	         if (pat[-1] == '*')
	             len = item_len;
	         if (item_len > len) {
	             memcat(outstring, oi, aptr, len);
	         } else {
	             memcat(outstring, oi, aptr, item_len);
	             len -= item_len;
	             if (datumtype == 'C') {
	                 while (len >= 10) {
	                     memcat(outstring, oi, space10, 10);
	                     len -= 10;
	                 }
	                 memcat(outstring, oi, space10, len);
	             }
	             else {
	                 while (len >= 10) {
	                     memcat(outstring, oi, null10, 10);
	                     len -= 10;
	                 }
	                 memcat(outstring, oi, null10, len);
	             }
	         }
	         break;

	     /* [pP]: S/390 packed decimal.  In this case, the length given
	        in the template is the length of a single field, not a
	        number of repetitions. */
	     case 'p':
	     case 'P':
	         if (len > 16) {
	            croak("Field length too large in packeb: %c%d", datumtype, len);
	         }
	         item = ST(ii);
	         ii++;
	         adouble = SvNV(item);

	         CF_num2packed(eb_work, adouble, len, ndec, datumtype=='P');
	         memcat(outstring, oi, eb_work, len);
	         break;

	     /* i: S/390 fullword (signed). */
	     case 'i':
	         for (j = 0; j < len; j++) {
	            item = ST(ii);
	            ii++;
	            along = SvIV(item);
	            _to_S390fw(eb_work, along);
	            memcat(outstring, oi, eb_work, 4);
	         }
	         break;

	     /* [sS]: S/390 halfword (signed/unsigned). */
	     case 's':
	     case 'S':
	         for (j = 0; j < len; j++) {
	            item = ST(ii);
	            ii++;
	            along = SvIV(item);
	            if (datumtype == 's') {
	               _to_S390hw(eb_work, along);
	               memcat(outstring, oi, eb_work, 2);
	            } else {
	               _to_S390fw(eb_work, along);
	               memcat(outstring, oi, eb_work+2, 2);
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
	         item = ST(ii);
	         ii++;
	         adouble = SvNV(item);

	         CF_num2zoned(eb_work, adouble, len, ndec);
	         memcat(outstring, oi, eb_work, len);
	         break;

	     case 'H':
	     case 'h':
	         {
	             char *hexstring;
	             I32 workbyte, xi; /* xi = index into hexstring */
	             unsigned char hexbyte, final_byte;

	             item = ST(ii);
	             ii++;
	             hexstring = SvPV(item, item_len);
	             if (pat[-1] == '*')
	                 len = item_len;
	             if (len < 2)
	                 len = 2;
	             if (len > item_len)
	                 len = item_len;
	             workbyte = 0;
	             for (xi = 0; xi < len; xi++) {
	                 hexbyte = (unsigned char) hexstring[xi];
	                 if (isALPHA(hexbyte))
	                     workbyte |= ((hexbyte & 15) + 9) & 15;
	                 else
	                     workbyte |= hexbyte & 15;
	                 if (! (xi & 1))
	                     workbyte <<= 4;
	                 else {
	                     final_byte = workbyte & 0xFF;
	                     memcat(outstring, oi, &final_byte, 1);
	                     workbyte = 0;
	                 }
	             }
	             if (xi & 1) {
	                 final_byte = workbyte & 0xFF;
	                 memcat(outstring, oi, &final_byte, 1);
	             }
	         }
	         break;

	     /* t: Unix time value to SMF timestamp */
	     case 't':
	         for (j = 0; j < len; j++) {
	            item = ST(ii);
	            ii++;
	            along = SvIV(item);
	            _clock_to_smfstamp(eb_work, along);
	            memcat(outstring, oi, eb_work, 8);
	         }
	         break;

	     default:
	        croak("Invalid type in packeb: '%c'", datumtype);
	   }
	}

	PUSHs(sv_2mortal(newSVpvn(outstring, oi)));
#ifdef DEBUG390
	fprintf(stderr, "*D* packeb: returning\n");
#endif


 # unpackeb -- Unpack an EBCDIC record into a list
 # Note that the EBCDIC data may contain nulls and other unprintable
 # stuff, so we need an SV*, not just a char*.
void
unpackeb(pat, ebrecord)
	char *  pat
	SV *    ebrecord
	PROTOTYPE: $$
	PREINIT:
	SV *sv;
	STRLEN rlen;

	register char *s;
	char *tail;
	char *strend;
	register char *patend;
	char datumtype;
	register I32 len, bits, outlen;
	int i, j, ndec, fieldlen;
	char hexdigit[16] = "0123456789abcdef";

	/* Work fields */
	I32 along;
	unsigned long aulong;
	/* Some day we may want to support S/390 floats.... */
	/*float afloat;*/
	double adouble;
	/* The eb_work area is long, but what the heck?  Memory is cheap. */
	char eb_work[32800];

	PPCODE:
#ifdef DEBUG390
	fprintf(stderr, "*D* unpackeb: beginning\n");
#endif
	s = SvPV(ebrecord, rlen);
	strend = s + rlen;
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
	   fprintf(stderr, "*D* unpackeb: datumtype/len %c%d\n",
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
	       CF_fcs_xlate(eb_work, s, len, e2a_table);
	       outlen = len;
	       if (len < 1)
	          eb_work[0] = 0x00;  /* Force an empty string. */
	       if (datumtype == 'E') {  /* Strip nulls and spaces */
	          tail = eb_work + len - 1;
	          while (tail >= eb_work && (*tail==' ' || *tail=='\0'))
	              tail--;
	          outlen = tail - eb_work + 1;
	       }

	       XPUSHs(sv_2mortal(newSVpvn(eb_work, outlen)));
	       s += len;
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
	          sv = UNDEF_PTR;
	       }

	       XPUSHs(sv_2mortal(sv));
	       s += len;
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
	          sv = UNDEF_PTR;
	       }

	       XPUSHs(sv_2mortal(sv));
	       s += len;
	       break;

	   /* [Cc]: characters without translation */
	   case 'C':
	   case 'c':
	       if (len > strend - s)
	          len = strend - s;
	       XPUSHs(sv_2mortal(newSVpvn(s, len)));
	       s += len;
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

	          XPUSHs(sv_2mortal(newSViv(along)));
	       }
	       break;

	   /* s: short integer (System/390 halfword) */
	   case 's':
	       if (len > (strend - s) / 2)
	          len = (strend - s) / 2;
	       for (i=0; i < len; i++) {
	          along = _halfword(s);

	          XPUSHs(sv_2mortal(newSViv(along)));
	          s += 2;
	       }
	       break;

	   /* [hH]: unpack to printable hex digits.  The length given
	      in the template is the length of a single field, not
	      a number of repetitions. */
	   case 'h':
	   case 'H':
	       if (len > (strend - s) * 2)
	          len = (strend - s) * 2;
	       if (len < 1)
	          eb_work[0] = 0x00;  /* Force an empty string. */
	       i = 0;
	       along = len;
	       for (len = 0; len < along; len++) {
	           if (len & 1)
	               bits <<= 4;
	           else
	               bits = *s++;
	           eb_work[i++] = hexdigit[(bits >> 4) & 15];
	       }
	       eb_work[i] = '\0';
	       XPUSHs(sv_2mortal(newSVpvn(eb_work, len)));
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
	           if (fieldlen > 0) {
	              CF_fcs_xlate(eb_work, s, fieldlen, e2a_table);
	              sv = newSVpvn(eb_work, fieldlen);
	           } else if (fieldlen == 0) {
	              sv = newSVpvn("", 0);
	           } else {
	              sv = UNDEF_PTR;
	           }
	           XPUSHs(sv_2mortal(sv));
	           s += fieldlen;
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
	      Therefore, to be safe, we compute this as an unsigned long
	      and then cast it to a double. */
	   case 'I':
	       if (len > (strend - s) / 4)
	          len = (strend - s) / 4;
	       if (sizeof(unsigned long) < 4) {
	          warn("Unsigned integer results may be invalid");
	       }
	       for (i=0; i < len; i++) {
	          aulong = 0;
	          for (j=0; j < 4; j++) {
	             aulong <<= 8;
	             aulong += (unsigned char) *s;  s++;
	          }

	          XPUSHs(sv_2mortal(newSVnv((double) aulong)));
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

	          XPUSHs(sv_2mortal(newSViv(along)));
	       }
	       break;

	   /* t: SMF date+time (8 bytes) to Unix time value */
	   case 't':
	       if (len > (strend - s) / 8)
	          len = (strend - s) / 8;
	       for (i=0; i < len; i++) {
	          along = _smfstamp_to_clock(s);
	          XPUSHs(sv_2mortal(newSViv(along)));
	          s += 8;
	       }
	       break;

	   default:
	       croak("Invalid type in unpackeb: '%c'", datumtype);
	   }
	}
#ifdef DEBUG390
	fprintf(stderr, "*D* unpackeb: returning\n");
#endif
