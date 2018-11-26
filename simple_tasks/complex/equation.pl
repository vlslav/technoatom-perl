#!/usr/bin/env perl

use 5.016;
use warnings;

sub run {
	my ($a, $b, $c) = @_;
	if ($a == 0) {
		die "Not a quadratic equation\n";
	}
	my $d = ($b ** 2 - 4 * $a * $c);
	if ($d >= 0) {
		die "Solutions in real numbers\n";
	}
	else {
		my $x1 = -$b / (2 * $a) . " + " . sqrt(abs($d)) / (2 * $a) . "i";
		my $x2 = -$b / (2 * $a) . " - " . sqrt(abs($d)) / (2 * $a) . "i";
		print "$x1, $x2\n";
	}
}


run(@ARGV);
