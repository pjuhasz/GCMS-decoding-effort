#!/usr/bin/perl

use strict;
use warnings;
use feature qw/say/;

# can't help but slurp the entire file
my $s;
{
	$/ = undef;
	open my $F, '<', $ARGV[0] or die "Can't open $ARGV[0]";
	$s = <$F>;
	close $F;
}

# Go through the file, locate the frame headers
my @header_offsets;
while ($s =~ /( (?: \x64\x00 | \xa0\x01 ) [\x00\x01\x02] \x00 [\x00\x01\x02] [^\x00] )/gx) {
	push @header_offsets, $-[0];
}
push @header_offsets, length $s;

for my $i (0..$#header_offsets-1) {
	my $o = $header_offsets[$i];
	my $d = $header_offsets[$i+1] - $o;
	my $frame_type = unpack "n", substr $s, $o, 2;
	my $scan_counter = unpack "n", substr $s, $o+47, 2;
	my $frame_mod_16 = unpack "C", substr $s, $o+49, 1;
	say join " ",
		$i, $o, $d, $scan_counter, $frame_mod_16,
		map('0x'.$_, unpack("(H4)37", substr $s, $o, 37*2)),
		map(unpack_v1_triplet(\$s, $o + 78 + $_*4), 0..($d-74)/4-2); # if $frame_type == 0xa001 and $frame_mod_16 == 0;
}

sub unpack_v1_triplet {
	my ($sref, $o) = @_;
	my $tmp = unpack "N", substr $$sref, $o, 4;
	return (
		($tmp & 0b11111111100000000000000000000000) >> 23,
		($tmp & 0b00000000011111111100000000000000) >> 14,
		($tmp & 0b00000000000000000011111111100000) >>  5,
	);
}
