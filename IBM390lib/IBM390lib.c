#include <math.h>
#include "./IBM390lib.h"
/*----------------------------------------------------------
  The C functions defined here correspond to the routines
  in IBM390.pm, but are faster than straight Perl code.
----------------------------------------------------------*/


/*---------- Packed Decimal In ----------*/
double  CFUNC_pdi
  ( unsigned char * packed,
    int    plength,
    int    ndec )
{
 double  out_num = 0;
 short   inv_packed, i;
 unsigned char  signum;

 for (i = 0; i < plength; i++) {
    out_num = (out_num * 10) + (*(packed + i) >> 4);
    if (i < plength - 1)
       out_num = (out_num * 10) + (*(packed + i) & 0x0F);
    else
       signum = *(packed + i) & 0x0F;
 }
 if (signum == 0x0D || signum == 0x0B) {
    out_num = 0 - out_num;
 }

  /* If ndec is 0, we're finished; if it's nonzero,
     correct the number of decimal places. */
 if ( ndec != 0 ) {
    out_num = out_num / pow(10.0, (double) ndec);
 }

 return out_num;
}


/*---------- Packed Decimal Out ----------*/
void  CFUNC_pdo
  ( unsigned char  *packed_ptr,
    double perlnum,
    int    outbytes,
    int    ndec )
{
 int     outdigits, i;
 double  perl_absval;
 unsigned char   digits[36];
 unsigned char  *digit_ptr, *out_ptr;
 unsigned char   signum;

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

 return;
}

/*---------- Full Collating Sequence Translate ----------*/
void  CFUNC_fcs_xlate
  ( unsigned char  *outstring,
    unsigned char  *instring,
    int  instring_len,
    unsigned char  *to_table )
{
 unsigned char  *out_ptr;
 int  i;

 out_ptr = outstring;
 for (i = 0; i < instring_len; i++) {
    (*out_ptr) = *(to_table + *(instring + i));
    out_ptr++;
 }
 return;
}
