#include <stdio.h>
#include <time.h>
/*-------------------------------------------------------------------
  Module:  Convert::IBM390
  The C functions defined here are faster than straight Perl code.
-------------------------------------------------------------------*/


 /* Powers of 10 */
double pow10[32] = { 1.0, 10.0, 100.0, 1000.0, 10000.0,
  100000.0,    1000000.0,    10000000.0,
  1.0E8,  1.0E9,  1.0E10, 1.0E11, 1.0E12, 1.0E13, 1.0E14, 1.0E15,
  1.0E16, 1.0E17, 1.0E18, 1.0E19, 1.0E20, 1.0E21, 1.0E22, 1.0E23,
  1.0E24, 1.0E25, 1.0E26, 1.0E27, 1.0E28, 1.0E29, 1.0E30, 1.0E31 };

/*---------- Test for a valid packed decimal field ----------*/
int _valid_packed (
  const char * packed_str,
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
    out_num = out_num / pow10[ndec];
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
    int    ndec,
    int    fsign )
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
    perl_absval = perlnum;   signum = (fsign) ? 0x0F : 0x0C;
 } else {
    perl_absval = 0 - perlnum;  signum = 0x0D;
 }
   /* sprintf will round to an "integral" value. */
 if (ndec == 0) {
    sprintf(digits, "%031.0f", perl_absval);
 } else {
    sprintf(digits, "%031.0f", perl_absval * pow10[ndec]);
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
    out_num = out_num / pow10[ndec];
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
    sprintf(digits, "%031.0f", perl_absval * pow10[ndec]);
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


/*---------- Full Collating Sequence Translate ----------
 * This function is like tr/// but assumes that the searchstring
 * is a complete 8-bit collating sequence (x'00' - x'FF').
 * The last argument is one of the translation tables defined
 * in IBM390lib.h (a2e_table, etc.).
 *-------------------------------------------------------*/
void  CF_fcs_xlate
  ( char  *outstring,
    char  *instring,
    int    instring_len,
    unsigned char  *to_table )
{
 char  *out_ptr;
 unsigned char offset;
 register int    i;

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


/*---------- Long integer to System/390 fullword ----------*/
void _to_S390fw (
  char * out_word,
  long   n )
{
 long  comp;

 if (n >= 0) {
    out_word[0] = (char) (n / 16777216);
    out_word[1] = (char) (n / 65536) % 256;
    out_word[2] = (char) (n / 256) % 256;
    out_word[3] = (char) (n % 256);
 } else {
    comp = (-n) - 1;  /* Complement */
    out_word[0] = (char) (comp / 16777216);
    out_word[1] = (char) (comp / 65536) % 256;
    out_word[2] = (char) (comp / 256) % 256;
    out_word[3] = (char) (comp % 256);
     /* Invert all bits. */
    out_word[0] = out_word[0] ^ 0xFF;
    out_word[1] = out_word[1] ^ 0xFF;
    out_word[2] = out_word[2] ^ 0xFF;
    out_word[3] = out_word[3] ^ 0xFF;
 }
 return;
}


/*---------- Long integer to System/390 halfword ----------*/
void _to_S390hw (
  char * out_word,
  long   n )
{
 long  comp;

 if (n > 32767 || n < -32768) {
    n = n % 32768;
 }
 if (n >= 0) {
    out_word[0] = (char) ((n / 256) % 256);
    out_word[1] = (char) (n % 256);
 } else {
    comp = (-n) - 1;  /* Complement */
    out_word[0] = (char) ((comp / 256) % 256);
    out_word[1] = (char) (comp % 256);
     /* Invert all bits. */
    out_word[0] = out_word[0] ^ 0xFF;
    out_word[1] = out_word[1] ^ 0xFF;
 }
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


/*---------- Convert Unix time to an SMF timestamp ----------*/

void _clock_to_smfstamp (
  char *  result,
  long    uclock )
{
 struct tm * T0;
 long    smft_csec;  /* SMF time in centiseconds */
 double  smf_jdate;  /* SMF Julian date */

 T0 = gmtime(&uclock);
  /* Compute time in centiseconds, assuming 00 fractional seconds. */
 smft_csec = (T0->tm_hour * 360000) + (T0->tm_min * 6000)
     + (T0->tm_sec * 100);
  /* Year since 1900 followed by Julian day. */
 smf_jdate = (T0->tm_year * 1000.0) + (T0->tm_yday + 1);

 _to_S390fw(result, smft_csec);
 CF_num2packed(result+4, smf_jdate, 4, 0, 1);

 return;
}


/*---------- Unpack SMF time to hh, mm, ss, centiseconds ----------*/

void _smftime_unpack (
  short * results,
  const char * smf_time )
{
 long    smft_csec;  /* SMF time is in centiseconds */
 long    remaining;
 short   hh, mm, ss, csec;

  /* The high-order byte must be 0, so we ignore it. */
 smft_csec = (((unsigned char) smf_time[1]) << 16)
        + (((unsigned char) smf_time[2]) << 8)
        + (unsigned char) smf_time[3];

 hh = smft_csec / 360000;  /* Truncating integer division */
 remaining = smft_csec - (hh * 360000);
 mm = remaining / 6000;
 remaining = remaining - (mm * 6000);
 ss = remaining / 100;
 csec = remaining - (ss * 100);

 results[0] = hh;     results[1] = mm;
 results[2] = ss;     results[3] = csec;
}


/*---------- Unpack SMF date to yyyy, mm, dd ----------*/

 /* Days Before This Month, Leap and Common years */
short dbtm_com[12] = 
   { 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334 };
short dbtm_leap[12] = 
   { 0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335 };

void _smfdate_unpack (
  short * results,
  const char * smf_date )
{
 unsigned char   smf_byte;
 short   yyyy, mm, dd, jday;
 short * dbtm_ptr;

  /* If this is not a valid packed number, bail. */
 if (! _valid_packed(smf_date, 4)) {
    results[0] = 0;
    return;
 }

 yyyy = (smf_date[0] + 19) * 100;
 smf_byte = (unsigned char) smf_date[1];
 yyyy += ((smf_byte >> 4) * 10) + (smf_byte & 0x0F);

  /* Julian day */
 smf_byte = (unsigned char) smf_date[2];
 jday = ((smf_byte >> 4) * 100) + ((smf_byte & 0x0F) * 10);
 smf_byte = (unsigned char) smf_date[3];
 jday += smf_byte >> 4;

  /* Is this a common year? */
 if ((yyyy % 4) || ((yyyy % 100 == 0) && (yyyy % 400))) {
    dbtm_ptr = dbtm_com;
 } else {
    dbtm_ptr = dbtm_leap;
 }
 for (mm = 11; mm >= 0; mm--) {
    if (jday > dbtm_ptr[mm]) {
       dd = jday - dbtm_ptr[mm];
       mm++;
       break;
    }
 }

 results[0] = yyyy;   results[1] = mm;
 results[2] = dd;
}


/*---------- SMF time+date to UNIX time value ----------*/

time_t  _smfstamp_to_clock (
  const char * smf_stamp )
{
 short   unpacked_time[4],  unpacked_date[3];
 struct tm  our_time;

 putenv("TZ=GMT0   ");  tzset();

 _smftime_unpack(unpacked_time, smf_stamp);
 _smfdate_unpack(unpacked_date, smf_stamp+4);

 our_time.tm_sec   = unpacked_time[2];
 our_time.tm_min   = unpacked_time[1];
 our_time.tm_hour  = unpacked_time[0];
 our_time.tm_mday  = unpacked_date[2];
 our_time.tm_mon   = unpacked_date[1] - 1;
 our_time.tm_year  = unpacked_date[0] - 1900;
 our_time.tm_isdst = 0;

 return mktime(&our_time);
}
