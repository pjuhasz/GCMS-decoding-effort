#!/usr/bin/perl

use strict;
use warnings;
use feature qw/say/;

my $debug = 0;

sub unpack_viking_float {
	my ($v) = @_;
	my $tmp = unpack "l>", $v;
	my $m = int($tmp / 256);
	$m-- if $m < 0;
	my $e = ($tmp & 0xff) - 128 - 23;
	if ($debug) {
		return join "\t", $m * 2 ** $e, unpack("H*", $v), unpack("B*", $v), $m, $e;
	} else {
		return $m * 2 ** $e;
	}
}

open my $F, '<', $ARGV[0] or die;
local $/ = \1282;

my $header = <$F>;
for (
	['Number of scans',                        0x470],
	['Run number',                             0x4b0],
	['Processed on year',                      0x4ae],
	['Processed on month',                     0x4ac],
	['Processed on day',                       0x4aa],
	['Serial Number',                          0x4a8],
	['Last RIC used in Volts-to-amps curve 1', 0x4a6],
	['Last RIC used in Volts-to-amps curve 2', 0x4a4],
) {
	my $v = substr $header, $_->[1], 2;
	say '# '.join "\t", $_->[0], unpack "n", $v;
}
for (
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
){
	my $v = substr $header, $_->[1], 4;
	say '# '.join "\t", $_->[0], unpack_viking_float($v);
}

say "#";

my $scan = 1;
while (my $record = <$F>) {
	for (
		['MIT scan number', 0x2],
		['Run number',      0x4],
		#['?',               0x6], # always 1?
		['Scan Number',     0x8],
	) {
		my $v = substr $record, $_->[1], 2;
		say '# '.join "\t", $_->[0], unpack "n", $v;
	}
	for my $mz (1..230) {
		my $v = substr $record, 1282-4*$mz, 4;
		say join "\t", $scan, $mz, unpack_viking_float($v);
	}
	say "";
	$scan++;
}
