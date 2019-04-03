#!/usr/bin/perl

# TODO: known row header fields

=pod

=head1 NAME

decode_v2_raw.pl - Decode a binary file from the Viking-2 GCMS raw data set

=head1 SYNOPSIS

	decode_v2_raw.pl [-s CHAR] [ -r | -t ] [-H] [-h] FILE

=head1 DESCRIPTION

Parse one binary data file from the Viking-2 GCMS raw data set, and
print its decoded contents to the standard output. By default, each
sample is written in a new row, prefixed with the scan and index number,
with a newline between scans. However, there are options
to use a more compact tabular output format, or to print row headers
(engineering data frames) or print all raw frames instead.

As the Viking-2 raw files are known to store samples in reverse order,
this script corrects the ordering and writes the samples in increasing
m/z order.
 
=head1 OPTIONS

=over

=item B<-s|--sep CHAR>

Set column separator character. Default is a TAB.

=item B<-H|--hex>

Print decoded integers in hexadecimal instead of decimal.

=item B<-t|--tabular>

Print the data in a compact tabular format instead. (One scan per row,
no header data or auxiliary information)

=item B<-r|--rowheaders>

Print data from row headers instead.

=item B<-h|--help>

Print help and exit.

=back

=cut

use strict;
use warnings;
use feature qw/say/;
use Getopt::Long qw/:config no_ignore_case bundling/;
use Pod::Usage;

# table with offsets of known fields
my @rowheader = (
	[0x00, ''],
	[0x2e, ''],
	[0x30, 'initial mission scan number'],
	[0x3c, ''],
	[0x3e, ''],
	[0x40, ''],
	[0x42, ''],
	[0x44, ''],
	[0x46, ''],
	[0x48, ''],
	[0x4a, ''],
	[0x4c, ''],
	[0x4e, ''],
	[0x50, ''],
	[0x52, ''],
	[0x54, ''],
	[0x56, ''],
	[0x58, ''],
	[0x5a, ''],
	[0x5c, ''],
	[0x5e, ''],
	[0x60, 'effluent divider status?'],
	[0x62, ''],
	[0x64, ''],
	[0x66, ''],
	[0x68, ''],
	[0x6a, 'modulo 16 counter'],
	[0x6c, 'MIT Scan number'],
	[0x6e, 'Mission scan number'],
	[0x70, 'frame counter?'],
	[0x72, ''],
	[0x74, ''],
	[0x76, 'Frames valid'],
	[0x78, 'Mission scan number 2'],
);

# parse command line options
my $sep = "\t";
my ($print_rowheaders, $print_tabular, $print_hex, $help);
GetOptions(
	'hex|H!'          => \$print_hex,
	'sep|s=s'         => \$sep,
	'rowheaders|r!'   => \$print_rowheaders,
	'tabular|t!'      => \$print_tabular,
	'help|h!'         => \$help,
) or die pod2usage(-exitval => 1, -verbose => 1);
die pod2usage(-exitval => 1, -verbose => 2) if $help;
die pod2usage(-exitval => 1, -verbose => 0) unless $ARGV[0];

if ($print_hex) {
	*f = \&format_hex;
} else {
	*f = \&nop;
}

my $stride = 7802;
my $hsize = 122;

local $/ = \$stride;

open my $F, '<:raw', $ARGV[0] or die "Can't open $ARGV[0]";

if ($print_rowheaders) {
	say "# Row headers";
	say join $sep, map {$_->[1] ? qq{"$_->[1]"} : $_->[0]} @rowheader;
	while (my $record = <$F>) {
		say join $sep, map {f(get_i16(\$record, $_->[0]))} @rowheader;
	}
	exit;
}

while (my $record = <$F>) {
	my $real_scan_id = get_i16(\$record, 0x6c);
	my @scan = reverse unpack "n*", substr $record, $hsize, $stride - $hsize;
	if ($print_hex) {
		@scan = map f($_), @scan;
	}
	if ($print_tabular) {
		say join $sep, @scan
	} else {
		# Print some identification information from the row header before
		# the data
		for (@rowheader[28,27,26,21,32]) {
			say '# '.join $sep, $_->[1], get_i16(\$record, $_->[0]);
		}
		for my $mz (0..3839) {
			say join $sep, $real_scan_id, $mz+1, $scan[$mz];
		}
		say "";
	}
}


###########################################
# helper function to read and convert a 16 bit integer from
# the given offset of a string (to be passed as a reference)
sub get_i16 {
	my ($sr, $offset) = @_;
	return unpack 'n', substr $$sr, $offset, 2;
}

sub nop {
	$_[0];
}

sub format_hex {
	return sprintf "0x%x", $_[0];
}
