package Convert::IBM390::CP00273;

use Convert::IBM390 'set_translation';

use vars qw($VERSION);

$VERSION = '0.26';

sub import {
  set_translation(undef, <<'END EBCDIC');
00 01 02 03 9C 09 86 7F 97 8D 8E 0B 0C 0D 0E 0F
10 11 12 13 9D 0A 08 87 18 19 92 8F 1C 1D 1E 1F
80 81 82 83 84 85 17 1B 88 89 8A 8B 8C 05 06 07
90 91 16 93 94 95 96 04 98 99 9A 9B 14 15 9E 1A
20 A0 E2 7B E0 E1 E3 E5 E7 F1 C4 2E 3C 28 2B 21
26 E9 EA EB E8 ED EE EF EC 7E DC 24 2A 29 3B 5E
2D 2F C2 5B C0 C1 C3 C5 C7 D1 F6 2C 25 5F 3E 3F
F8 C9 CA CB C8 CD CE CF CC 60 3A 23 A7 27 3D 22
D8 61 62 63 64 65 66 67 68 69 AB BB F0 FD FE B1
B0 6A 6B 6C 6D 6E 6F 70 71 72 AA BA E6 B8 C6 A4
B5 DF 73 74 75 76 77 78 79 7A A1 BF D0 DD DE AE
A2 A3 A5 B7 A9 40 B6 BC BD BE AC 7C AF A8 B4 D7
E4 41 42 43 44 45 46 47 48 49 AD F4 A6 F2 F3 F5
FC 4A 4B 4C 4D 4E 4F 50 51 52 B9 FB 7D F9 FA FF
D6 F7 53 54 55 56 57 58 59 5A B2 D4 5C D2 D3 D5
30 31 32 33 34 35 36 37 38 39 B3 DB 5D D9 DA 9F
END EBCDIC
} # end import

__END__

=head1 NAME

Convert::IBM390::CP00273 - EBCDIC Austria, Germany

=head1 SYNOPSIS

      Code Page 00273: EBCDIC Austria, Germany

     -0 -1 -2 -3 -4 -5 -6 -7 -8 -9 -A -B -C -D -E -F
  0- 00 01 02 03 9C 09 86 7F 97 8D 8E 0B 0C 0D 0E 0F
  1- 10 11 12 13 9D 0A 08 87 18 19 92 8F 1C 1D 1E 1F
  2- 80 81 82 83 84 85 17 1B 88 89 8A 8B 8C 05 06 07
  3- 90 91 16 93 94 95 96 04 98 99 9A 9B 14 15 9E 1A
  4- 20 A0 E2 7B E0 E1 E3 E5 E7 F1 C4 2E 3C 28 2B 21
  5- 26 E9 EA EB E8 ED EE EF EC 7E DC 24 2A 29 3B 5E
  6- 2D 2F C2 5B C0 C1 C3 C5 C7 D1 F6 2C 25 5F 3E 3F
  7- F8 C9 CA CB C8 CD CE CF CC 60 3A 23 A7 27 3D 22
  8- D8 61 62 63 64 65 66 67 68 69 AB BB F0 FD FE B1
  9- B0 6A 6B 6C 6D 6E 6F 70 71 72 AA BA E6 B8 C6 A4
  A- B5 DF 73 74 75 76 77 78 79 7A A1 BF D0 DD DE AE
  B- A2 A3 A5 B7 A9 40 B6 BC BD BE AC 7C AF A8 B4 D7
  C- E4 41 42 43 44 45 46 47 48 49 AD F4 A6 F2 F3 F5
  D- FC 4A 4B 4C 4D 4E 4F 50 51 52 B9 FB 7D F9 FA FF
  E- D6 F7 53 54 55 56 57 58 59 5A B2 D4 5C D2 D3 D5
  F- 30 31 32 33 34 35 36 37 38 39 B3 DB 5D D9 DA 9F
