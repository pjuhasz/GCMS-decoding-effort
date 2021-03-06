#!/usr/bin/perl


=pod

=head1 NAME

convert_raw.pl - Convert a decoded file from the Viking GCMS raw data

=head1 SYNOPSIS

	convert_raw.pl [-d] [-s CHAR] [-t NUMBER] [-a] [-c] [-h] FILE

=head1 DESCRIPTION

Convert one decoded text data file (emitted by either C<decode_v1_raw.pl>
or C<decode_v2_raw.pl>) so that the vertical and horizontal axes are
transformed to the same scale as those of the reduced dataset. The
result is printed to the standard output.

By default, the program operates in peak detection mode, that is, the
maximum calculated ion current is selected from the mass number range
[m-t, m+t] (where t is a threshold value, by default 0.5), and only that
single value (the candidate peak) is printed for each mass number.

With the C<-a> option peak detection is disabled, all points from the
input are printed after the (vertical and horizontal) transformation
functions are applied to them.

The C<-c> option facilitates comparison with the corresponding reduced
file.

NB: The appropriate calibration constants for the transformation functions
are selected by the input filename, which must follow the template
C<DR00tttt_F---nn.decoded>, where C<tttt> is either 5967 or 5289, and
C<nn> goes from 01 to 10. In other words, input file names must be derived
from the originals with the extension changed to C<.decoded>.

=head1 OPTIONS

=over

=item B<-s|--sep CHAR>

Set column separator character. Default is a TAB.

=item B<-a|--all-points>

Disable peak detection, print all transformed points.

=item B<-t|--threshold NUMBER>

Change the peak detection mass number threshold, by default 0.5.

=item B<-c|--compare>

Read the corresponding reduced file too, and for each scan and mass number
print both the transformed value from the raw file and the corresponding
number from the reduced file.

=item B<-d|--debug>

In peak detection mode print the calculated (likely non-integer)
mass number of the candidate peak in an additional column.

=item B<-h|--help>

Print help and exit.

=back

=cut

use strict;
use warnings;
use feature qw/say/;
use Getopt::Long qw/:config no_ignore_case bundling/;
use Pod::Usage;

my %constants = (
	'DR005967_F00006.decoded' => {
	# Run number	10007
		invert_horizontal => 1,
		raw_file => 'DR005388_F00001.decoded',
		vt1 => 55,
		vt2 => 110,
		tA  => 0.000330402282997966,
		tB  => 1.06191396713257,
		mA  => -0.763399958610535,
		mB  => 0.00876100547611713,
		v1A => -38.9401473999023,
		v1B => 0.944003820419312,
		v1C => -0.00848989374935627,
		v2A => -14.8579692840576,
		v2B => 0.0481690242886543,
		v2C => -0.000162942189490423,
		v3A => -13.0036487579346,
		v3B => 0.0136960987001657,
	},
	'DR005967_F00007.decoded' => {
	# Run number	10032
		invert_horizontal => 1,
		raw_file => 'DR005388_F00002.decoded',
		vt1 => 55,
		vt2 => 110,
		tA  => 0.000330842973198742,
		tB  => 1.06235790252686,
		mA  => -0.763399958610535,
		mB  => 0.00876100547611713,
		v1A => -38.9401473999023,
		v1B => 0.944003820419312,
		v1C => -0.00848989374935627,
		v2A => -14.8579692840576,
		v2B => 0.0481690242886543,
		v2C => -0.000162942189490423,
		v3A => -13.0036487579346,
		v3B => 0.0136960987001657,
	},
	'DR005967_F00008.decoded' => {
	# Run number	10033
		invert_horizontal => 1,
		raw_file => 'DR005388_F00003.decoded',
		vt1 => 55,
		vt2 => 110,
		tA  => 0.000330842973198742,
		tB  => 1.06235790252686,
		mA  => -0.763399958610535,
		mB  => 0.00876100547611713,
		v1A => -38.9401473999023,
		v1B => 0.944003820419312,
		v1C => -0.00848989374935627,
		v2A => -14.8579692840576,
		v2B => 0.0481690242886543,
		v2C => -0.000162942189490423,
		v3A => -13.0036487579346,
		v3B => 0.0136960987001657,
	},
	'DR005967_F00009.decoded' => {
	# Run number	10034
		invert_horizontal => 1,
		raw_file => 'DR005388_F00004.decoded',
		vt1 => 55,
		vt2 => 110,
		tA  => 0.000330842973198742,
		tB  => 1.06235790252686,
		mA  => -0.763399958610535,
		mB  => 0.00876100547611713,
		v1A => -38.9401473999023,
		v1B => 0.944003820419312,
		v1C => -0.00848989374935627,
		v2A => -14.8579692840576,
		v2B => 0.0481690242886543,
		v2C => -0.000162942189490423,
		v3A => -13.0036487579346,
		v3B => 0.0136960987001657,
	},
	'DR005967_F00010.decoded' => {
	# Run number	10035
		invert_horizontal => 1,
		raw_file => 'DR005388_F00005.decoded',
		vt1 => 55,
		vt2 => 110,
		tA  => 0.000330842973198742,
		tB  => 1.06235790252686,
		mA  => -0.763399958610535,
		mB  => 0.00876100547611713,
		v1A => -38.9401473999023,
		v1B => 0.944003820419312,
		v1C => -0.00848989374935627,
		v2A => -14.8579692840576,
		v2B => 0.0481690242886543,
		v2C => -0.000162942189490423,
		v3A => -13.0036487579346,
		v3B => 0.0136960987001657,
	},
	'DR005967_F00001.decoded' => {
	# Run number	10036
		invert_horizontal => 1,
		raw_file => 'DR005388_F00006.decoded',
		vt1 => 55,
		vt2 => 110,
		tA  => 0.000330842973198742,
		tB  => 1.06235790252686,
		mA  => -0.763399958610535,
		mB  => 0.00876100547611713,
		v1A => -38.9401473999023,
		v1B => 0.944003820419312,
		v1C => -0.00848989374935627,
		v2A => -14.8579692840576,
		v2B => 0.0481690242886543,
		v2C => -0.000162942189490423,
		v3A => -13.0036487579346,
		v3B => 0.0136960987001657,
	},
	'DR005967_F00002.decoded' => {
	# Run number	10037
		invert_horizontal => 1,
		raw_file => 'DR005388_F00007.decoded',
		vt1 => 55,
		vt2 => 110,
		tA  => 0.000330842973198742,
		tB  => 1.06235790252686,
		mA  => -0.763399958610535,
		mB  => 0.00876100547611713,
		v1A => -38.9401473999023,
		v1B => 0.944003820419312,
		v1C => -0.00848989374935627,
		v2A => -14.8579692840576,
		v2B => 0.0481690242886543,
		v2C => -0.000162942189490423,
		v3A => -13.0036487579346,
		v3B => 0.0136960987001657,
	},
	'DR005967_F00003.decoded' => {
	# Run number	10038
		invert_horizontal => 1,
		raw_file => 'DR005388_F00008.decoded',
		vt1 => 55,
		vt2 => 110,
		tA  => 0.000330842973198742,
		tB  => 1.06235790252686,
		mA  => -0.763399958610535,
		mB  => 0.00876100547611713,
		v1A => -38.9401473999023,
		v1B => 0.944003820419312,
		v1C => -0.00848989374935627,
		v2A => -14.8579692840576,
		v2B => 0.0481690242886543,
		v2C => -0.000162942189490423,
		v3A => -13.0036487579346,
		v3B => 0.0136960987001657,
	},
	'DR005967_F00004.decoded' => {
	# Run number	10039
		invert_horizontal => 1,
		raw_file => 'DR005388_F00009.decoded',
		vt1 => 55,
		vt2 => 110,
		tA  => 0.000330842973198742,
		tB  => 1.06235790252686,
		mA  => -0.763399958610535,
		mB  => 0.00876100547611713,
		v1A => -38.9401473999023,
		v1B => 0.944003820419312,
		v1C => -0.00848989374935627,
		v2A => -14.8579692840576,
		v2B => 0.0481690242886543,
		v2C => -0.000162942189490423,
		v3A => -13.0036487579346,
		v3B => 0.0136960987001657,
	},
	'DR005967_F00005.decoded' => {
	# Run number	10041
		invert_horizontal => 1,
		raw_file => 'DR005388_F00010.decoded',
		vt1 => 55,
		vt2 => 110,
		tA  => 0.000330842973198742,
		tB  => 1.06235790252686,
		mA  => -0.763399958610535,
		mB  => 0.00876100547611713,
		v1A => -38.9401473999023,
		v1B => 0.944003820419312,
		v1C => -0.00848989374935627,
		v2A => -14.8579692840576,
		v2B => 0.0481690242886543,
		v2C => -0.000162942189490423,
		v3A => -13.0036487579346,
		v3B => 0.0136960987001657,
	},
	'DR005289_F00004.decoded' => {
	# Run number	10008
		invert_vertical => 1,
		raw_file => 'DR005631_F00001.decoded',
		vt1 => 60,
		vt2 => 112,
		tA  => 0.000329889997374266,
		tB  => 1.07194399833679,
		mA  => -0.763399958610535,
		mB  => 0.00876100547611713,
		v1A => -50.7097244262695,
		v1B => 1.24799799919128,
		v1C => -0.0102433189749718,
		v2A => -15.4362697601318,
		v2B => 0.0579058229923248,
		v2C => -0.000205721182283014,
		v3A => -13.0402088165283,
		v3B => 0.0137846190482378,
	},
	'DR005289_F00005.decoded' => {
	# Run number	10015
		invert_vertical => 1,
		raw_file => 'DR005631_F00002.decoded',
		vt1 => 60,
		vt2 => 112,
		tA  => 0.000330119975842535,
		tB  => 1.07104396820068,
		mA  => -0.763399958610535,
		mB  => 0.00876100547611713,
		v1A => -50.7097244262695,
		v1B => 1.24799799919128,
		v1C => -0.0102433189749718,
		v2A => -15.4362697601318,
		v2B => 0.0579058229923248,
		v2C => -0.000205721182283014,
		v3A => -13.0402088165283,
		v3B => 0.0137846190482378,
	},
	'DR005289_F00006.decoded' => {
	# Run number	10018
		invert_vertical => 1,
		raw_file => 'DR005631_F00003.decoded',
		vt1 => 60,
		vt2 => 112,
		tA  => 0.000330440350808203,
		tB  => 1.0711817741394,
		mA  => -0.763399958610535,
		mB  => 0.00876100547611713,
		v1A => -50.7097244262695,
		v1B => 1.24799799919128,
		v1C => -0.0102433189749718,
		v2A => -15.4362697601318,
		v2B => 0.0579058229923248,
		v2C => -0.000205721182283014,
		v3A => -13.0402088165283,
		v3B => 0.0137846190482378,
	},
	'DR005289_F00001.decoded' => {
	# Run number	10023
		invert_vertical => 1,
		raw_file => 'DR005631_F00004.decoded',
		vt1 => 60,
		vt2 => 112,
		tA  => 0.000330440350808203,
		tB  => 1.0711817741394,
		mA  => -0.763399958610535,
		mB  => 0.00876100547611713,
		v1A => -50.7097244262695,
		v1B => 1.24799799919128,
		v1C => -0.0102433189749718,
		v2A => -15.4362697601318,
		v2B => 0.0579058229923248,
		v2C => -0.000205721182283014,
		v3A => -13.0402088165283,
		v3B => 0.0137846190482378,
	},
	'DR005289_F00002.decoded' => {
	# Run number	10024
		invert_vertical => 1,
		raw_file => 'DR005631_F00005.decoded',
		vt1 => 60,
		vt2 => 112,
		tA  => 0.000330440350808203,
		tB  => 1.0711817741394,
		mA  => -0.763399958610535,
		mB  => 0.00876100547611713,
		v1A => -50.7097244262695,
		v1B => 1.24799799919128,
		v1C => -0.0102433189749718,
		v2A => -15.4362697601318,
		v2B => 0.0579058229923248,
		v2C => -0.000205721182283014,
		v3A => -13.0402088165283,
		v3B => 0.0137846190482378,
	},
	'DR005289_F00003.decoded' => {
	# Run number	10025
		invert_vertical => 1,
		raw_file => 'DR005631_F00006.decoded',
		vt1 => 60,
		vt2 => 112,
		tA  => 0.000330440350808203,
		tB  => 1.0711817741394,
		mA  => -0.763399958610535,
		mB  => 0.00876100547611713,
		v1A => -50.7097244262695,
		v1B => 1.24799799919128,
		v1C => -0.0102433189749718,
		v2A => -15.4362697601318,
		v2B => 0.0579058229923248,
		v2C => -0.000205721182283014,
		v3A => -13.0402088165283,
		v3B => 0.0137846190482378,
	}
);

# parse command line options
my $sep = "\t";
my ($debug, $print_all_points, $compare, $help);
my $threshold = 0.5;
GetOptions(
	'debug|d!'      => \$debug,
	'sep|s=s'       => \$sep,
	'all_points|a!' => \$print_all_points,
	'threshold|t=f' => \$threshold,
	'compare|c!'    => \$compare,
	'help|h!'       => \$help,
) or die pod2usage(-exitval => 1, -verbose => 1);
die pod2usage(-exitval => 1, -verbose => 2) if $help;
die pod2usage(-exitval => 1, -verbose => 0) unless $ARGV[0];

my @scans;

my $fn = $ARGV[0];

die "No constants defined for $fn" unless defined $constants{$fn};

open my $F, '<', $fn or die "Can't open $fn";

# precompute scaled x and y table
my (@h, @v);
for (1..3840) {
	$h[$_] = h($_, $fn);
}
for (0..511) {
	$v[$_] = v($_, $fn);
}

for (<$F>) {
	next if /^#/;
	my ($s, $x, $y) = split;
	next unless defined $x and defined $y;
	push @{$scans[$s]}, [$h[$x], $v[$y]];
}

close $F;

my @reduced_data;
if ($compare) {
	my $rfn = $constants{$fn}{raw_file};
	open my $F, '<', $rfn or die "Can't open reduced data file $rfn";
	for (<$F>) {
		next if /^#/;
		my ($s, $x, $y) = split;
		next unless defined $x and defined $y;
		$reduced_data[$s][$x] = $y;
	}
	close $F;
}

if ($print_all_points) {
	for my $s (0..$#scans) {
		next unless defined $scans[$s];
		for (@{$scans[$s]}) {
			say join $sep, $s, @$_;
		}
		say "";
	}
} else {
	for my $s (0..$#scans) {
		next unless defined $scans[$s];
		my @reduced;
		for (@{$scans[$s]}) {
			my $int_m = int($_->[0] + 0.5);
			if (abs($_->[0] - $int_m) < $threshold) {
				push @{$reduced[$int_m]}, $_;
			}
		}
		for my $m (12..220) {
			my $sorted = [ sort {$b->[1] <=> $a->[1]} @{$reduced[$m]} ];
			my $maxm = $sorted->[0]->[0];
			my $maxv = $sorted->[0]->[1];
			if (not defined $maxv) {
				$maxv = -1;
				$maxm = $m;
			}
			my @out = ($s, $m, $maxv);
			push @out, $reduced_data[$s][$m] // -1 if $compare;
			push @out, $maxm if $debug;
			say join $sep, @out;
		}
		
		say "";
	}
}


#####################################################

sub h {
	my ($x, $f) = @_;
	my $c = $constants{$f};
	#$x = 3841 - $x if $c->{invert_horizontal};
	return 10 ** ($c->{tA} * $x + $c->{tB});
}

sub v {
	my ($x, $f) = @_;
	my $c = $constants{$f};
	$x = 511 - $x if $c->{invert_vertical};
	my $v =
		$x > $c->{vt2} ? $c->{v3B} * $x + $c->{v3A} :
		$x > $c->{vt1} ? $c->{v2C} * $x**2 + $c->{v2B} * $x + $c->{v2A} :
						$c->{v1C} * $x**2 + $c->{v1B} * $x + $c->{v1A};
	return 10 ** $v;
}

