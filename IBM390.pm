package Convert::IBM390;
$VERSION = '0.17';

#--- DUMMY ----------------------------------------------------------
#
# This is a dummy .pm file, needed only because CPAN expects one.
# To generate the real thing, run 'perl Makefile.PL'.
#
#--- DUMMY ----------------------------------------------------------

1;
__END__

=head1 NAME

Convert::IBM390 -- functions for manipulating mainframe data

=head1 SYNOPSIS

  use Convert::IBM390 qw(...those desired... or :all);

  $eb  = asc2eb($string);
  $asc = eb2asc($string);
  $asc = eb2ascp($string);

  $ebrecord = packeb($template, LIST...);
  @fields = unpackeb($template, $record);
  @lines = hexdump($string [,startaddr [,charset]]);

=head1 DESCRIPTION

B<Convert::IBM390> supplies various functions that you may find useful
when messing with IBM System/3[679]0 data.  No functions are exported
automatically; you must ask for the ones you want.  "use ... qw(:all)"
exports all functions.

By the way, this module is called "IBM390" because it will deal with
data from any mainframe operating system.  Nothing about it is
specific to MVS, VM, VSE, or OS/390.

=head1 FUNCTIONS

=over 2

=item B<asc2eb> STRING

Converts a character string from ASCII to EBCDIC.  The translation
table is taken from the LE/370 code set converter EDCUI1EY; it
translates ISO8859-1 to IBM-1047.  For more information, see "IBM
C/C++ for MVS/ESA V3R2 Programming Guide", SC09-2164.

=item B<eb2asc> STRING

Converts a character string from EBCDIC to ASCII.  EBCDIC character
strings ordinarily come from files transferred from mainframes
via the binary option of FTP.  The translation table is taken from
the LE/370 code set converter EDCUEYI1; it translates IBM-1047 to
ISO8859-1 (see above).

=item B<eb2ascp> STRING

Like eb2asc, but the output will contain only printable ASCII characters.

=item B<packeb> TEMPLATE LIST

This function is much like Perl's built-in "pack".  It takes a list
of values and packs it into an EBCDIC record (structure).  If
called in list context, it will return a list of one element.
The TEMPLATE is patterned after Perl's pack template but allows fewer
options.  The following characters are allowed in the template:

  c  (1)  Character string without translation, padded with nulls
  C  (1)  Character string without translation, padded with native
          spaces
  e  (1)  ASCII string to be translated into EBCDIC, padded with nulls
  E  (1)  ASCII string to be translated into EBCDIC, padded with EBCDIC
          spaces
  h  (1)  A hexadecimal string, high nybble always first
  i  (2)  Signed integer (S/390 fullword)
  p  (1)  Packed-decimal field (default length = 8)
  P  (1)  Packed-decimal field with F signs for positive numbers
          (sometimes called "unsigned") (default length = 8)
  s  (2)  Signed short integer (S/390 halfword)
  S  (2)  Unsigned short integer (2 bytes)	
  t  (2)  SMF timestamp (time + date, 8 bytes)
  x  (2)  A null byte
  z  (1)  Zoned-decimal field (default length = 8)
  @       Null-fill to absolute offset

 (1) May be followed by a number giving the length of the output field;
     or, for hexadecimal, the number of nybbles in the input.
 (2) May be followed by a number giving the repeat count.

Each character may be followed by a number giving either the length
of the field or a repeat count, as shown above.  Types 'i', 's', and
'S' will gobble the specified number of items from the list; if '*' is
given as the length, all the remaining items will be gobbled.  All
other types will gobble only one item; you will usually want to give
a length for the output field.  The following defaults apply:

  Conversion                No length given   '*' given
  Character string [cCeE]   1                 Same length as input
  Hex string [hH]           2                 Same length as input
  Decimal [pz]              8                 8

The number must immediately follow the character, but whitespace may
appear between field specifiers.

The length for packed (p) or zoned (z) fields may include a number
of decimal places,
which is added after the byte count and a '.'.  For instance, "p3.2"
indicates a 3-byte (5-digit) packed field with 2 implied decimal
places; if the corresponding list element is 24.68, the result will
be x'02468C'.
Likewise, "z7.2" indicates a 7-byte (7-digit) zoned field with 2
implied decimal places; if the input is -35.79, the result will be
'000357R' in EBCDIC.
The number of implied decimals may be greater than the number of digits,
but such a specification will usually cause you to lose part of your
value; e.g., packing .589 with "p3.6" would yield x'89000c'.
If the input is not a valid Perl number, the results are unpredictable
(since they depend on internal Perl code), but most likely the output
field will contain zero.

'p' will produce packed fields with the preferred sign characters: 
C for positive, D for negative. 'P' will produce F for positive
(sometimes called "unsigned") and D for negative.

Zoned output will always have an overpunch in the last byte for the sign
(e.g., x'C1' (EBCDIC 'A') for +1 or x'D3' (EBCDIC 'L') for -3).  If
you want unsigned numbers, you can use sprintf() and then translate
the result: e.g., C<asc2eb(sprintf("%08d", $num))>.

The ASCII-to-EBCDIC translation used by [Ee] is the same as in
asc2eb().

Either 'h' or 'H' may be used to request hexadecimal conversion.  This
conversion is exactly the same as in the Perl pack function, except
that the high nybble must always come first in the input.

Type 't' takes a Unix time value (integer) and produces an SMF
timestamp (a 4-byte time followed by a 4-byte date).  Since this
module cannot be aware of the time zone on the target mainframe, the
time value is treated as if it were UTC (GMT).  You may have to
adjust the time accordingly; for instance, if your target mainframe
is running on Eastern time, you will probably want to subtract 
18000 (= 5 hours * 3600 sec/hr) from the time before packing it.

The maximum length of a packed field is 16 bytes; of a zoned field, 32
bytes.  All other fields may have a maximum specifier (length or repeat
count) of 32767.  The maximum length of the output structure is 36KB.
These maxima are enforced.

=item B<unpackeb> TEMPLATE RECORD

This function is much like Perl's built-in "unpack".  It takes an
EBCDIC record (structure) and unpacks it into a list of values.  If
called in scalar context, it will return only the first unpacked value.
The TEMPLATE is patterned after Perl's unpack template but allows fewer
options.  The following characters are allowed in the template:

  c or C (1)   Character string without translation
  e or E (1)   EBCDIC string to be translated into ASCII
  i      (2)   Signed integer (S/390 fullword)
  I      (2)   Unsigned integer (4 bytes)
  p      (1)   Packed-decimal field
  s      (2)   Signed short integer (S/390 halfword)
  S      (2)   Unsigned short integer (2 bytes)	
  t      (2)   SMF timestamp (time + date, 8 bytes)
  v      (2)   EBCDIC varchar string
  x      (1)   Ignore these bytes
  z      (1)   Zoned-decimal field

 (1) May be followed by a number giving the length of the field.
 (2) May be followed by a number giving the repeat count.

Each character may be followed by a number giving either the length
of the field or a repeat count, as shown above, or by '*', which means
to use however many items are left in the string.  The number must
immediately follow the character, but whitespace may appear between
field specifiers.

The length for packed (p) or zoned (z) fields may include a number
of decimal places,
which is added after the byte count and a '.'.  For instance, "p3.2"
indicates a 3-byte (5-digit) packed field with 2 implied decimal
places; if this field contains x'02468C', the result will be 24.68.
Likewise, "z7.2" indicates a 7-byte (7-digit) zoned field with 2
implied decimal places; if this field contains '000357R' (in EBCDIC),
the result will be -35.79.
The number of implied decimals may be greater than the number of digits;
e.g., unpacking the packed field above with "p3.6" would yield 0.002468.
Zoned input fields may, but need not, have an overpunch sign in the
last byte.
If the field is not a valid packed or zoned field, the resulting
element of the list will be undefined.

Varchar (v) fields are assumed to consist of a signed halfword (16-bit)
integer followed by EBCDIC characters.  If the number appearing in the
initial halfword is N, the following N bytes are translated from EBCDIC
to ASCII and returned as one string.  This format is used, for
instance, by DB2/MVS.  A repeat count may be specified; e.g., "v2" does
not mean a length of 2 bytes, but that there are two such fields in
succession.  If the length is found to be less than 0, the resulting
element of the list will be undefined.

The EBCDIC-to-ASCII translation used by [Eev] is the same as in
eb2asc().

Type 't' reads an SMF timestamp (a 4-byte time followed by a 4-byte
date) and produces a Unix time value.  The hundredths of a second
in the SMF time field are discarded.  Since this
module cannot be aware of the time zone on the source mainframe, the
time value is treated as if it were UTC (GMT).  You may have to
adjust the time accordingly; for instance, if your source mainframe
is running on Eastern time, you will probably want to add
18000 (= 5 hours * 3600 sec/hr) to the result after unpacking.

The maximum length of a packed field is 16 bytes; of a zoned field, 32
bytes.  All other fields may have a maximum specifier (length or repeat
count) of 32767.  These maxima are enforced.

In most cases, you should use 'i' rather than 'I' when unpacking
fullword integers.  Unsigned long integers are not handled cleanly by
all systems.

=item B<hexdump> STRING [STARTADDR [CHARSET]]

Generates a hexadecimal dump of STRING.  The dump is similar to a
SYSABEND dump in MVS: each line contains an address, 32 bytes of data
in hexadecimal, and the same data in printable form.  This function
returns a list of lines, each of which is terminated with a newline.
This allows them to be printed immediately; for instance, you can say
"print hexdump($crud);".

The second and third arguments are optional.  The second specifies 
a starting address for the dump (default = 0); the third specifies
the character set to use for the printable data at the end of each
line ("ascii" or "ebcdic", in upper or lower case; default = ascii).

=item B<version>

Returns a string identifying the version of this module.  This
function is not exported; it must be called as
C<Convert::IBM390::version>.

=back

=head1 A COBOL EXAMPLE

Suppose you have a mainframe record described thus in Cobol:

 01  ACPDB-RECORD.
     03  ACPDB-FIRST-DATE-TRANS.
         05  ACPDB-FD-TRANS-CN   PIC XX.
         05  ACPDB-FD-TRANS-YR   PIC XX.
         05  ACPDB-FD-TRANS-MO   PIC XX.
         05  ACPDB-FD-TRANS-DA   PIC XX.
     03  ACPDB-LAST-DATE-TRANS.
         05  ACPDB-LD-TRANS-CN   PIC XX.
         05  ACPDB-LD-TRANS-YR   PIC XX.
         05  ACPDB-LD-TRANS-MO   PIC XX.
         05  ACPDB-LD-TRANS-DA   PIC XX.
     03  ACPDB-TOTAL-ITEMS       PIC S9(9)       COMP.
     03  ACPDB-TOTAL-NO-TRANS    PIC S9(5)       COMP-3.
     03  ACPDB-TOTAL-DOLLARS-1   PIC S9(7)V99    COMP-3.
     03  ACPDB-PREV-YR-DOLLARS   PIC S9(7)V99    COMP-3.
     03  ACPDB-RETURNED-ITEMS    PIC S9(4)       COMP.
     03  ACPDB-DOLL-CD-PREV-BASE PIC XX.

You would unpack the record like this:

  @fields = unpackeb('e8 e8 i p3.0 p5.2 p5.2 s e2', $inrecord)

=head1 REFERENCES

IBM ESA/390 Principles of Operation, SA22-7201.

IBM System/370 Principles of Operation, GA22-7000.

IBM C/C++ for MVS/ESA V3R2 Programming Guide, SC09-2164.

z/OS MVS System Management Facilities (SMF), SA22-7630,
s.v. "Standard SMF Record Header".

=head1 BUGS

None, of course.  What do you think this is -- Unix?

=head1 AUTHOR

Convert::IBM390 was written by Geoffrey Rommel
E<lt>GROMMEL@cpan.orgE<gt>
in January 1999.
Thanks to Barry Roomberg for the Cobol example.

=cut
