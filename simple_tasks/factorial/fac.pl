#!/usr/bin/env perl

use 5.016;
use warnings;

sub fac {
	my $n = shift;
	if (int $n == $n && $n >= 0) {
		return _fac($n,1);
	}
	else {
		die "Entered is not a natural number";
	}
}

sub _fac {
	my ($n, $acc) = @_;
	return $acc if $n == 0;
	@_ = ($n - 1, $n * $acc); 
	goto &_fac;
}

say fac(shift @ARGV);