#!/usr/bin/perl

=pod

=head1 NAME decode_reduced_dataset.pl - Decode the binary files of the Viking GCMS reduced data set

=head1 SYNOPSIS

	decode_reduced_dataset.pl [-d] [-s CHAR] [-r] [-e] [-h] FILE

=head1 OPTIONS

=over

=item B<-s|--sep CHAR>

Set column separator character. Default is a TAB.

=item B<-d|--debug>

Verbose output for floating point numbers.
For each decoded number print the hexadecimal and binary representation
and the calculated mantissa and exponent.

=item B<-r|--rowheaders>

Print data from row headers instead.

=item B<-e|-effluent>

Print the table of the (suspected) effluent numbers from the header instead.

=item B<-h|--help>

Print help and exit.

=back

=cut

use strict;
use warnings;
use feature qw/say/;
use Getopt::Long;
use Pod::Usage;

# tables with offsets of known fields
my @header_i16 = (
	['Number of scans',                        0x470],
	['Run number',                             0x4b0],
	['Processed on year',                      0x4ae],
	['Processed on month',                     0x4ac],
	['Processed on day',                       0x4aa],
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
		['',     0x010],
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
my ($debug, $print_rowheaders, $print_effluent_table, $help);
GetOptions(
	'debug|d!'      => \$debug,
	'sep|s=s'       => \$sep,
	'rowheaders|r!' => \$print_rowheaders,
	'effluent|e!'   => \$print_effluent_table,
	'help|h!'       => \$help,
) or die pod2usage(-exitval => 1, -verbose => 1);
die pod2usage(-exitval => 1, -verbose => 2) if $help;
die pod2usage(-exitval => 1, -verbose => 0) unless $ARGV[0];

open my $F, '<', $ARGV[0] or die "Can't open $ARGV[0]\n";

# read file in fixed length chunks
local $/ = \1282;

# read the header and print some of the known fields from it
my $header = <$F>;
for (@header_i16) {
	say '# '.join $sep, $_->[0], get_i16(\$header, $_->[1]);
}
for (@header_float){
	say '# '.join $sep, $_->[0], get_float(\$header, $_->[1]);
}

say "#";

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
			say "# missing scan $missing";
			say join $sep, $missing, 1, "missing";
			say "";
		}
	}
	$last_scan_id = $real_scan_id;

	# Print some identification information from the row header before
	# the data
	for (@rowheader[0..3]) {
		say '# '.join $sep, $_->[0], get_i16(\$record, $_->[1]);
	}
	for my $mz (1..230) {
		say join $sep, $real_scan_id, $mz, get_float(\$record, 1282 - 4*$mz);
	}
	say "";
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
