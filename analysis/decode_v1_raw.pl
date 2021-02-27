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
	[0x00, 1, 'C', 'logical_record_flag'],
	[0x02, 2, 'n', 'logical_record_length'], # the field begins at byte 1, but the first byte is always 0
	[0x04, 4, 'N', 'ttag'],
	[0x08, 1, 'C', 'spc'],
	[0x09, 1, 'C', 'tcf'],
	[0x0a, 2, 'n', 'dayear'],
	[0x0c, 1, 'C', 'spare1'],
	[0x0d, 1, 'C', 'cat_flag'],
	[0x0e, 1, 'C', 'scc'],
	[0x0f, 1, 'C', 'dqual'],
	[0x10, 1, 'C', 'berr'],
	[0x11, 1, 'C', 'year'],
	[0x12, 2, 'n', 'snr'],
	[0x14, 1, 'C', 'dss'],
	[0x15, 1, 'C', 'lock'],
	[0x16, 2, 'n', 'config'],
	[0x18, 1, 'C', 'special_data_type'],
	[0x19, 1, 'C', 'gdd'],
	[0x1a, 2, 'n', 'ndbr'],
	[0x1c, 1, 'C', 'agcsmp'],
	[0x1d, 1, 'C', 'hsderr'],
	[0x1e, 2, 'n', 'datrat'],
	[0x20, 4, 'N', 'avagc'],
	[0x24, 2, 'n', 'spare2'],
	[0x26, 2, 'n', 'sdrrec'],
	[0x28, 2, 'n', 'seq'],
	[0x2a, 2, 'n', 'vmcind'],
	[0x2c, 1, 'C', 'vl_fmtid'],
	[0x2d, 2, 'n', 'scan_counter'],
	[0x2f, 1, 'C', 'mod_16_frame_counter'],
	[0x30, 4, 'N', 'GCSC_time_follows'],
	[0x36, 1, 'C', 'reset_counter'], # the field begins at offset 0x34, but the first 2 bytes are always 0
	[0x37, 1, 'C', 'vosnr'],
	[0x39, 2, 'n', 'cont_frame_counter_2'], # the field begins at offset 0x38, but the first 2 bytes are always 0
	[0x3b, 1, 'C', 'prior'],
	[0x3c, 4, 'N', 'GCSC_time_preceded'],
	[0x40, 2, 'n', 'sdrrec'],
	[0x42, 1, 'C', 'iqual'],
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

# magic translation table from EBCDIC to ASCII (from perlebcdic)
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

my $first_real_scan_offset;

# read the file packet by packet, length prefix first
while ($read = sysread $F, $s, 2) {
	# first, get the length then the contents of this packet
	die "Error reading file $ARGV[0]" unless defined $read;
	last if $read == 0;
	my $len = unpack "v", $s; # packet length is _little endian_

	# sanity check
	die "Invalid frame length $len, file is possibly damaged or doesn't have the right format\n" if $len > 416;

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

	# Kludge to determine the offset between the real scan number
	# (that starts around 283) and the MIT scan number which starts at 1:
	# Normally the first complete, real scan corresponds to MIT scan 1,
	# except in run 10008 (V-1 cruise oven characterization, DR005289_F00004),
	# where the raw file has scans 282 and 283, while the reduced file
	# begins with 284, as MIT scan 2. The run id is not present in the raw
	# files, so we have to rely on the fact that this misbehaving run is
	# also the only one with length 50 packets.
	if ($len == 80) {
		$first_real_scan_offset = 282;
	} elsif ($len == 416 and not defined $first_real_scan_offset) {
		$first_real_scan_offset = $scan_count - 1;
	}

	# print all frames and exit if required
	if ($print_frames) {
		print join $sep, $frame_count, $offset, $len, $scan_count, $frame_mod_16, '';
		if ($len == 80) {
			# decode the reversed EBCDIC information text
			my $string = substr $s, 0, 80;
			eval '$string =~ tr/' . $cp_037 . '/\000-\377/';
			$string =~ s/\x00+$//;
			$string =~ s/\x80|\x00/ /g;
			say qq{"$string"};
		} elsif ($len < 100) {
			# short headerless frame
			say join $sep, map f($_), unpack "n".($len/2), substr $s, 0, $len;
		} else {
			# short or long data frame
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
			# FIXME entire missing scans are not indicated or replaced
			my $full_scan = assemble_frames(@current_scan);
			say join $sep, map f($_), @$full_scan if defined $full_scan;
		} else {
			# TODO some header info in comments
			my $full_scan = assemble_frames(@current_scan);
			if (defined $full_scan) {
				say join $sep, '# Scan number', $scan_count;
				say join $sep, '# Mit scan number', $scan_count - $first_real_scan_offset;
				say join $sep, '# Frames valid', calc_frames_valid_indicator(@current_scan);
				for my $i (0..$#$full_scan) {
					say join $sep, $scan_count - $first_real_scan_offset, $i+1, f($full_scan->[$i]);
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

sub calc_frames_valid_indicator {
	my $ind = 0;
	for my $i (1..15) {
		my $f = $_[$i];
		if (defined $f and scalar @$f >= 256) {
			$ind |= 1<<($i-1)
		}
	}
	return $ind;
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
