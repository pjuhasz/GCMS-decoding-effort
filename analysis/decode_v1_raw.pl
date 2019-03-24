#!/usr/bin/perl

# TODO:
# insert missing complete scans
# keep track of missing frames and create frame validity bitfield

=pod

=head1 NAME

decode_v1_raw.pl - Decode a binary file from the Viking GCMS reduced data set

=head1 SYNOPSIS

	decode_reduced_dataset.pl [-s CHAR] [-f | -r | -t ] [-k] [-H] [-h] FILE

=head1 DESCRIPTION

Parse one binary data file from the Viking-1 GCMS raw data set, and
print its decoded contents to the standard output. By default, each
sample is written in a new row, prefixed with the scan and index number,
with a newline between scans. However, there are options
to use a more compact tabular output format, or to print row headers
(engineering data frames) or print all raw frames instead.

Missing frames are recognized and handled so that the reassembled frames
always have the full 3840 samples. 511 is used to represent missing and
artificially inserted values.

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

Print data from row headers (16th frames with engineering data) instead.

=item B<-e|--frames>

Print all the raw frames (one per row) prefixed with the frame count,
offset, frame length, scan count and frame number within the scan, in
the order they were read from the file, including the short and
fragmented frames at the beginning and end of file and near missing
frames.

=item B<-k|keep-partial>

Keep data from short frames near missed frames. Sometimes the last frame
before a missed frame is short (with 19 data points instead of 256).
Normally, these are discarded and replaced with an all 511 fake frame.
With this option, data from them is kept and augmented with 511's to
make a full frame.

=item B<-h|--help>

Print help and exit.

=back

=cut
use strict;
use warnings;
use feature qw/say/;
use Getopt::Long qw/:config no_ignore_case bundling/;
use Pod::Usage;

# table with offsets, sizes and explanations of known fields
my @frameheader = (
	[0x00, 1, 'C', ''],
	[0x01, 1, 'C', ''],
	[0x02, 2, 'n', ''],
	[0x04, 4, 'N', 'millisecond_of_day'],
	[0x08, 2, 'n', ''],
	[0x0a, 2, 'n', 'day_counter'],
	[0x0c, 1, 'C', ''],
	[0x0d, 1, 'C', 'mod_16_counter'],
	[0x0e, 4, 'N', ''],
	[0x12, 2, 'n', ''],
	[0x14, 2, 'n', ''],
	[0x16, 2, 'n', ''],
	[0x18, 2, 'n', ''],
	[0x1a, 2, 'n', ''],
	[0x1c, 4, 'N', ''],
	[0x20, 1, 'C', ''],
	[0x21, 1, 'C', ''],
	[0x22, 1, 'C', ''],
	[0x24, 4, 'N', ''],
	[0x28, 2, 'n', 'cont_frame_counter_1'],
	[0x2a, 2, 'n', ''],
	[0x2c, 1, 'C', ''],
	[0x2d, 2, 'n', 'scan_counter'],
	[0x2f, 1, 'C', 'mod_16_frame_counter'],
	[0x30, 1, 'C', ''],
	[0x32, 2, 'n', ''],
	[0x34, 2, 'n', ''],
	[0x36, 1, 'C', 'reset_counter'],
	[0x37, 2, 'n', ''],
	[0x39, 2, 'n', 'cont_frame_counter_2'],
	[0x3b, 1, 'C', ''],
	[0x3c, 2, 'n', ''],
	[0x3e, 2, 'n', ''],
	[0x40, 4, 'N', ''],
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

if ($print_frames) {
	say '#'.join $sep, qw/"frame_count" "offset" "length" "scan_count" "frame_mod_16"/,
		map {$_->[3] ? qq{"$_->[3]"} : $_->[0]} @frameheader;
}

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
			print join $sep, map {f(unpack $_->[2], substr $s, $_->[0], $_->[1])} @frameheader;
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
