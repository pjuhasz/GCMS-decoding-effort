#!/usr/bin/perl

=pod

=head1 NAME

decode_reduced.pl - Decode a binary file from the Viking GCMS reduced data set

=head1 SYNOPSIS

	decode_reduced.pl [-d] [-s CHAR] [-r | -t | -e] [-h] FILE

=head1 DESCRIPTION

Parse one binary data file from the Viking-1 GCMS reduced data set, and
print its decoded contents to the standard output. By default, each
sample is written in a new row, prefixed with the scan and index number,
with a newline between scans. A few commented rows of metadata from the
scan headers are printed before each scan. However, there are options
to use a more compact tabular output format, or to print row headers,
the global file header, or the effluent divider table from the header
instead.

Missing scans are recognized and handled by inserting a fake scan of all
-1's.

=head1 OPTIONS

=over

=item B<-s|--sep CHAR>

Set column separator character. Default is a TAB.

=item B<-d|--debug>

Verbose output for floating point numbers.
For each decoded number print the hexadecimal and binary representation
and the calculated mantissa and exponent.

=item B<-t|--tabular>

Print the data in a compact tabular format instead. (One scan per row)

=item B<-r|--rowheaders>

Print data from row headers instead.

=item B<-e|--effluent>

Print the table of the (suspected) effluent numbers from the header instead.

=item B<-h|--help>

Print help and exit.

=back

=cut

use strict;
use warnings;
use feature qw/say/;
use Getopt::Long qw/:config no_ignore_case bundling/;
use Pod::Usage;

# tables with offsets of known fields
my @header_i16 = (
	['Number of scans',                        0x470],
	['Run number',                             0x4b0],
	['Processed on month',                     0x4ae],
	['Processed on day',                       0x4ac],
	['Processed on year',                      0x4aa],
	['Serial Number',                          0x4a8],
	['Last RIC used in Volts-to-amps curve 1', 0x4a6],
	['Last RIC used in Volts-to-amps curve 2', 0x4a4],
);

my @header_float = (
	['Time-to-mass A',      0x4a0],
	['Time-to-mass B',      0x49c],
	['Mass-compensation A', 0x498],
	['Mass-compensation B', 0x494],
	['Volts-to-amps (1) A', 0x490],
	['Volts-to-amps (1) B', 0x48c],
	['Volts-to-amps (1) C', 0x488],
	['Volts-to-amps (2) A', 0x484],
	['Volts-to-amps (2) B', 0x480],
	['Volts-to-amps (2) C', 0x47c],
	['Volts-to-amps (3) A', 0x478],
	['Volts-to-amps (3) B', 0x474],
);

my @rowheader = (
		['MIT scan number',   0x2],
		['Run number',        0x4],
		['Data present',      0x6],
		['Scan Number',       0x8],
		['Effluent divider?', 0x00a],
		['Frames valid',      0x010],
		['Init scan number',  0x012],
		['',     0x014],
		['',     0x0d8],
		['',     0x0e8],
		['',     0x0ea],
		['',     0x0ec],
		['',     0x0ee],
		['',     0x0f0],
		['',     0x0f2],
		['',     0x0f4],
		['',     0x0f6],
		['',     0x0f8],
		['',     0x0fa],
		['',     0x0fc],
		['',     0x0fe],
		['',     0x100],
		['',     0x102],
		['',     0x104],
		['',     0x106],
		['Effluent divider?', 0x108],
		['',     0x10a],
		['',     0x10c],
		['',     0x10e],
		['',     0x110],
		['Modulo 16 counter', 0x112],
		['MIT Scan number',   0x114],
		['Scan number',       0x116],
		['Counter?',          0x118],
);

# parse command line options
my $sep = "\t";
my ($debug, $print_rowheaders, $print_effluent_table, $print_tabular, $help);
GetOptions(
	'debug|d!'      => \$debug,
	'sep|s=s'       => \$sep,
	'rowheaders|r!' => \$print_rowheaders,
	'effluent|e!'   => \$print_effluent_table,
	'tabular|t!'    => \$print_tabular,
	'help|h!'       => \$help,
) or die pod2usage(-exitval => 1, -verbose => 1);
die pod2usage(-exitval => 1, -verbose => 2) if $help;
die pod2usage(-exitval => 1, -verbose => 0) unless $ARGV[0];

open my $F, '<', $ARGV[0] or die "Can't open $ARGV[0]\n";

# read file in fixed length chunks
local $/ = \1282;

# magic translation table from EBCDIC to ASCII (from perlebcdic)
# I've never imagined that I'll actually encounter EBCDIC in my life...
my $cp_037 =
	'\x00\x01\x02\x03\x37\x2D\x2E\x2F\x16\x05\x25\x0B\x0C\x0D\x0E\x0F' .
	'\x10\x11\x12\x13\x3C\x3D\x32\x26\x18\x19\x3F\x27\x1C\x1D\x1E\x1F' .
	'\x40\x5A\x7F\x7B\x5B\x6C\x50\x7D\x4D\x5D\x5C\x4E\x6B\x60\x4B\x61' .
	'\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\x7A\x5E\x4C\x7E\x6E\x6F' .
	'\x7C\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xD1\xD2\xD3\xD4\xD5\xD6' .
	'\xD7\xD8\xD9\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xBA\xE0\xBB\xB0\x6D' .
	'\x79\x81\x82\x83\x84\x85\x86\x87\x88\x89\x91\x92\x93\x94\x95\x96' .
	'\x97\x98\x99\xA2\xA3\xA4\xA5\xA6\xA7\xA8\xA9\xC0\x4F\xD0\xA1\x07' .
	'\x20\x21\x22\x23\x24\x15\x06\x17\x28\x29\x2A\x2B\x2C\x09\x0A\x1B' .
	'\x30\x31\x1A\x33\x34\x35\x36\x08\x38\x39\x3A\x3B\x04\x14\x3E\xFF' .
	'\x41\xAA\x4A\xB1\x9F\xB2\x6A\xB5\xBD\xB4\x9A\x8A\x5F\xCA\xAF\xBC' .
	'\x90\x8F\xEA\xFA\xBE\xA0\xB6\xB3\x9D\xDA\x9B\x8B\xB7\xB8\xB9\xAB' .
	'\x64\x65\x62\x66\x63\x67\x9E\x68\x74\x71\x72\x73\x78\x75\x76\x77' .
	'\xAC\x69\xED\xEE\xEB\xEF\xEC\xBF\x80\xFD\xFE\xFB\xFC\xAD\xAE\x59' .
	'\x44\x45\x42\x46\x43\x47\x9C\x48\x54\x51\x52\x53\x58\x55\x56\x57' .
	'\x8C\x49\xCD\xCE\xCB\xCF\xCC\xE1\x70\xDD\xDE\xDB\xDC\x8D\x8E\xDF';

# read the header and print some of the known fields from it
my $header = <$F>;
if (not $print_tabular) {
	# decode the reversed EBCDIC information text
	my $string = reverse substr $header, 0x4b2, 80;
	$string =~ s/(.)(.)/$2$1/g;
	eval '$string =~ tr/' . $cp_037 . '/\000-\377/';
	say '# Description' . $sep . $string;
	# decode the rest
	for (@header_i16) {
		say '# '.join $sep, $_->[0], get_i16(\$header, $_->[1]);
	}
	for (@header_float){
		say '# '.join $sep, $_->[0], get_float(\$header, $_->[1]);
	}
say "#";
}

if ($print_effluent_table) {
	# given the option, parse the table of effluent divider numbers from the header and exit 
	say "# Effluent divider table from the header";
	my $scans = get_i16(\$header, 0x470);
	for my $i (1..$scans) {
		say join $sep, $i, get_i16(\$header, 0x46c - 2*$i);
	}
	exit;
} elsif ($print_rowheaders) {
	# or print the data from the row headers
	say "# Row headers";
	say join $sep, map {$_->[0] ? qq{"$_->[0]"} : $_->[1]} @rowheader;
	while (my $record = <$F>) {
		say join $sep, map {get_i16(\$record, $_->[1])} @rowheader;
	}
	exit;
}

# Dump the actual data points, one row per point, with a blank line
# between records
my $last_scan_id = 0;
while (my $record = <$F>) {
	my $real_scan_id = get_i16(\$record, 0x2);
	if ($last_scan_id + 1 != $real_scan_id) {
		# At least one scan is missing from the file, insert one (or more)
		# fake record to draw attention to the fact
		# (and to keep the plot script simple)
		for my $missing ($last_scan_id+1 .. $real_scan_id-1) {
			if ($print_tabular) {
				say join $sep, (-1) x 230;
			} else {
				say "# missing scan $missing";
				for my $mz (1..230) {
					say join $sep, $missing, $mz, -1;
				}
				say "";
			}
		}
	}
	$last_scan_id = $real_scan_id;

	if ($print_tabular) {
		say join $sep, map get_float(\$record, 1282 - 4*$_), 1..230;
	} else {
		# Print some identification information from the row header before
		# the data
		for (@rowheader[0..5]) {
			say '# '.join $sep, $_->[0], get_i16(\$record, $_->[1]);
		}
		for my $mz (1..230) {
			say join $sep, $real_scan_id, $mz, get_float(\$record, 1282 - 4*$mz);
		}
		say "";
	}
}

#######################################
# helper function to read and convert a 16 bit integer from
# the given offset of a string (to be passed as a reference)
sub get_i16 {
	my ($sr, $offset) = @_;
	return unpack 'n', substr $$sr, $offset, 2;
}

# helper function to read and convert an IBM 1800 floating point number
# from the given offset of a string (to be passed as a reference)
sub get_float {
	my ($sr, $offset) = @_;
	return unpack_IBM1800_float(substr $$sr, $offset, 4);
}

# convert an IBM 1800 floating point number,
# passed as a raw 4 byte string to an usable Perl variable
# (conventional double precision number really)
#
# The IBM 1800 format uses 24 bits of mantissa in two's complement form
# plus 8 bits of exponent (biased by 128 or 129, depending on
# interpretation), in that order. There is no hidden bit normalization.
# Example: 04000081 is decoded to 1.0.
sub unpack_IBM1800_float {
	my ($v) = @_;

	# since it's in two's complement format already, read it as a signed integer
	my $tmp = unpack "l>", $v;

	# effectively shift right, keeping the sign
	my $m = int($tmp / 256);

	# correct for negative numbers
	$m-- if $m < 0;

	# calculate effective exponent from rightmost 8 bytes,
	# taking the bias and the necessary right shift into account
	my $e = ($tmp & 0xff) - 128 - 23;

	# what we've came for: perform the exponentiation
	my $res = $m * 2 ** $e;

	if ($debug) {
		return join "\t", $res, unpack("H*", $v), unpack("B*", $v), $m, $e;
	} else {
		return $res;
	}
}
