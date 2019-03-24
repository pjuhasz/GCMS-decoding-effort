#!/usr/bin/perl

# TODO document options

use strict;
use warnings;
use feature qw/say/;
use Getopt::Long qw/:config no_ignore_case bundling/;
use Pod::Usage;

# table with offsets of known fields
my @frameheader = (
# TODO
);

# parse command line options
my $sep = "\t";
my ($print_frames, $print_rowheaders, $print_tabular, $keep_partial, $print_hex, $help);
GetOptions(
	'hex|H!'          => \$print_hex,
	'sep|s=s'         => \$sep,
	'frames|f!'       => \$print_frames,
	'rowheaders|r!'   => \$print_rowheaders,
	'tabular|t!'      => \$print_tabular,
	'keep-partial|k!' => \$keep_partial,
	'help|h!'         => \$help,
) or die pod2usage(-exitval => 1, -verbose => 1);
die pod2usage(-exitval => 1, -verbose => 2) if $help;
die pod2usage(-exitval => 1, -verbose => 0) unless $ARGV[0];

if ($print_hex) {
	*f = \&format_hex;
} else {
	*f = \&nop;
}

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
			say join $sep, map f($_), unpack "n".($len/2), substr $s, 0, $len;
		} else {
			# short or long data frame
			# TODO known fields from header
			print join $sep, map f($_), unpack "n36", substr $s, 0, 72;
			print $sep;
			say join $sep, map f($_), @decoded_int9;
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
	if ($frame_mod_16 != 0) {
		$current_scan[$frame_mod_16] = \@decoded_int9;
	} else {
		if ($print_rowheaders) {
			say join $sep, $frame_count, $offset, $len, $scan_count, map f($_), @decoded_int9;
		} elsif ($print_tabular) {
			my $full_scan = assemble_frames(@current_scan);
			say join $sep, map f($_), @$full_scan if defined $full_scan;
		} else {
			# TODO some header info in comments
			my $full_scan = assemble_frames(@current_scan);
			if (defined $full_scan) {
				for my $i (0..$#$full_scan) {
					say join $sep, $scan_count, $i+1, f($full_scan->[$i]);
				}
				say "";
			}
		}
		@current_scan = ();
	}

	$frame_count++;
	$offset += $len + 2;
}


close $F;

#######################################
# assemble the contents of data frames into a complete scan.
# missing frames are replaced with 256 511's.
# short (frame length = 100) frames are either augmented or replaced, depending
# on a command line option so that a full frame always contains 3840 values
sub assemble_frames {
	return unless @_;
	my @scan;
	for my $i (1..15) {
		my $f = $_[$i];
		if (defined $f and scalar @$f >= 256) {
			push @scan, @{$f}[0..255];
		} elsif (defined $f and $keep_partial) {
			push @scan, @{$f}[0..18], (511) x (256-19);
		} else {
			push @scan, (511) x 256;
		}
	}
	return \@scan;
}

sub unpack_v1_triplet {
	my ($sref, $o) = @_;
	my $tmp = unpack "N", substr $$sref, $o, 4;
	warn "non-zero low bits at offset $o\n" if $tmp & 0b11111;
	return (
		($tmp & 0b11111111100000000000000000000000) >> 23,
		($tmp & 0b00000000011111111100000000000000) >> 14,
		($tmp & 0b00000000000000000011111111100000) >>  5,
	);
}

sub nop {
	$_[0];
}

sub format_hex {
	return sprintf "0x%x", $_[0];
}
