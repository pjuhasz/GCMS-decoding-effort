#!/usr/bin/perl


use strict;
use warnings;
use feature qw/say/;
use Getopt::Long;
use Pod::Usage;

# table with offsets of known fields
my @frameheader = (

);

# parse command line options
my $sep = "\t";
my ($print_frames, $print_rowheaders, $print_tabular, $print_hex, $help);
GetOptions(
	'hex|H!'        => \$print_hex,
	'sep|s=s'       => \$sep,
	'frames|f!'     => \$print_frames,
	'rowheaders|r!' => \$print_rowheaders,
	'tabular|t!'    => \$print_tabular,
	'help|h!'       => \$help,
) or die pod2usage(-exitval => 1, -verbose => 1);
die pod2usage(-exitval => 1, -verbose => 2) if $help;
die pod2usage(-exitval => 1, -verbose => 0) unless $ARGV[0];

open my $F, '<', $ARGV[0] or die "Can't open $ARGV[0]";

my ($read, $s);
my $frame_count = 0;
my $offset = 0;

my @current_scan;

# read the file packet by packet, length prefix first
while ($read = sysread $F, $s, 2) {
	# first, get the length then the contents of this packet
	die "Error reading file $ARGV[0]" unless defined $read;
	last if $read == 0;
	my $len = unpack "v", $s; # packet length is _little endian_
	$read = sysread $F, $s, $len;
	die "Error reading file $ARGV[0]" unless defined $read;
	last if $read == 0;

	# if it is a data frame, decode the data points right away
	my $scan_count   = 0;
	my $frame_mod_16 = 0;
	my @decoded_int9;
	if ($len >= 100) {
		$scan_count = unpack "n", substr $s, 45, 2;
		$frame_mod_16 = unpack "C", substr $s, 47, 1;
		@decoded_int9 = map unpack_v1_triplet(\$s, 72 + $_*4), 0..($len-72)/4-1;
	}

	# print all frames and exit if required
	if ($print_frames) {
		print join $sep, $frame_count, $offset, $len, $scan_count, $frame_mod_16, '';
		if ($len < 100) {
			# short headerless frame
			if ($print_hex) {
				say join $sep, map '0x'.$_, unpack "(H4)".($len/2), substr $s, 0, $len;
			} else {
				say join $sep, unpack "n".($len/2), substr $s, 0, $len;
			}
		} else {
			# short or long data frame
			# TODO known fields from header
			if ($print_hex) {
				print join $sep, map '0x'.$_, unpack "(H4)36", substr $s, 0, 72;
				print $sep;
				say join $sep, map sprintf("0x%x", $_), @decoded_int9;
			} else {
				print join $sep, unpack "n36".($len/2), substr $s, 0, 72;
				print $sep;
				say join $sep, @decoded_int9;
			}
		}
		$frame_count++;
		$offset += $len + 2;
		next;
	}

	# no need to bother with non-data frames anymore
	if ($len < 100) {
		$frame_count++;
		$offset += $len + 2;
		next;
	}

	# if it is a data frame, accumulate its contents
	# if it is an auxiliary frame, either print the data from that, or print the entire accumulated scan
	# TODO skipped, spliced frames, print_hex
	if ($frame_mod_16 != 0) {
		push @current_scan, @decoded_int9[0..255];
	} else {
		if ($print_rowheaders) {
			say join $sep, $frame_count, $offset, $len, $scan_count, @decoded_int9[0..20];
			# TODO something about contents of last auxiliary frame?
		} elsif ($print_tabular) {
			say join $sep, @current_scan if @current_scan;
		} else {
			# TODO some header info in comments
			for my $i (0..$#current_scan) {
				say join $sep, $scan_count, $i, $current_scan[$i];
			}
			say "" if @current_scan;
		}
		@current_scan = ();
	}

	$frame_count++;
	$offset += $len + 2;
}


close $F;

sub unpack_v1_triplet {
	my ($sref, $o) = @_;
	my $tmp = unpack "N", substr $$sref, $o, 4;
	return (
		($tmp & 0b11111111100000000000000000000000) >> 23,
		($tmp & 0b00000000011111111100000000000000) >> 14,
		($tmp & 0b00000000000000000011111111100000) >>  5,
	);
}
