#include <math.h>
/*-------------------------------------------------------------------
  Module:  Convert::IBM390
  The C functions defined here correspond to the routines
  in IBM390.pm, but are faster than straight Perl code.
-------------------------------------------------------------------*/


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


/*---------- Packed decimal to Perl number ----------*/
double  CF_packed2num
  ( char * packed,
    int    plength,
    int    ndec )
{
 double  out_num;
 short   i;
 unsigned char  pdigits, signum;

#ifdef DEBUG390
  fprintf(stderr, "*D* CF_packed2num: beginning\n");
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
  fprintf(stderr, "*D* CF_packed2num: returning %f\n", out_num);
#endif
 return out_num;
}


/*---------- Perl number to packed decimal ----------*/
void  CF_num2packed
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
  fprintf(stderr, "*D* CF_num2packed: beginning\n");
#endif
 if (perlnum >= 0) {
    perl_absval = perlnum;   signum = 0x0C;
 } else {
    perl_absval = 0 - perlnum;  signum = 0x0D;
 }
   /* sprintf will round to an "integral" value. */
 if (ndec == 0) {
    sprintf(digits, "%031.0f", perl_absval);
 } else {
    sprintf(digits, "%031.0f", perl_absval * pow(10.0, (double) ndec));
 }
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
  fprintf(stderr, "*D* CF_num2packed: returning\n");
#endif
 return;
}


/*---------- Test for a valid zoned decimal field ----------*/
int _valid_zoned (
  char * zoned_str,
  int    plen )
{
 int   i;
 unsigned char zdigit;

#ifdef DEBUG390
  fprintf(stderr, "*D* _valid_zoned: beginning\n");
#endif
 for (i = 0; i < plen; i++) {
    zdigit = (unsigned char) zoned_str[i];
    if (i < plen - 1) {
       if (zdigit < 0xF0 || zdigit > 0xF9)
          { return 0; }
    } else {
       if ((zdigit & 0xF0) < 0xA0 || (zdigit & 0x0F) > 0x09)
          { return 0; }
    }
 }

#ifdef DEBUG390
  fprintf(stderr, "*D* _valid_zoned: returning 1\n");
#endif
 return 1;
}


/*---------- Zoned decimal to Perl number ----------*/
double  CF_zoned2num
  ( char * zoned,
    int    plength,
    int    ndec )
{
 double  out_num;
 short   i;
 unsigned char  zdigit, signum;

#ifdef DEBUG390
  fprintf(stderr, "*D* CF_zoned2num: beginning\n");
#endif
 out_num = 0.0;
 for (i = 0; i < plength; i++) {
    zdigit = (unsigned char) *(zoned + i);
    if (i < plength - 1) {
       out_num = (out_num * 10) + (zdigit - 240);  /* i.e. 0xF0 */
    } else {
       out_num = (out_num * 10) + (zdigit & 0x0F);
       signum = zdigit & 0xF0;
    }
 }
 if (signum == 0xD0 || signum == 0xB0) {
    out_num = -out_num;
 }

  /* If ndec is 0, we're finished; if it's nonzero,
     correct the number of decimal places. */
 if ( ndec != 0 ) {
    out_num = out_num / pow(10.0, (double) ndec);
 }

#ifdef DEBUG390
  fprintf(stderr, "*D* CF_zoned2num: returning %f\n", out_num);
#endif
 return out_num;
}


/*---------- Perl number to zoned decimal ----------*/
void  CF_num2zoned
  ( char  *zoned_ptr,
    double perlnum,
    int    outbytes,
    int    ndec )
{
 int     i;
 double  perl_absval;
 char    digits[36];
 char   *digit_ptr, *out_ptr;
 unsigned char signum;

#ifdef DEBUG390
  fprintf(stderr, "*D* CF_num2zoned: beginning\n");
#endif
 if (perlnum >= 0) {
    perl_absval = perlnum;   signum = 0xC0;
 } else {
    perl_absval = 0 - perlnum;  signum = 0xD0;
 }
   /* sprintf will round to an "integral" value. */
 if (ndec == 0) {
    sprintf(digits, "%031.0f", perl_absval);
 } else {
    sprintf(digits, "%031.0f", perl_absval * pow(10.0, (double) ndec));
 }
 digit_ptr = digits;
 out_ptr = zoned_ptr;
 for (i = 31 - outbytes; i < 31; i++) {
    if (i < 30) {
       (*out_ptr) = (*(digit_ptr + i) - '0') | 0xF0;
    } else {
       (*out_ptr) = (*(digit_ptr + i) - '0') | signum;
    }
    out_ptr++;
 }

#ifdef DEBUG390
  fprintf(stderr, "*D* CF_num2zoned: returning\n");
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
