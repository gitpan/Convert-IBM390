/*----------------------------------------------------------
  Module:  Convert::IBM390
----------------------------------------------------------*/

int     _valid_packed ( char *, int );
double  CF_packed2num ( char *, int, int );
void    CF_num2packed ( char *, double, int, int );
int     _valid_zoned ( char *, int );
double  CF_zoned2num ( char *, int, int );
void    CF_num2zoned ( char *, double, int, int );
void    CF_fcs_xlate ( char *, char *, int, char * );
