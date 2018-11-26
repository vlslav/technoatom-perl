#!/usr/bin/env perl

use 5.016;
use warnings;

sub fib {
	if (int $_[0] == $_[0] && $_[0] > 0) {
		return 0 if $_[0] == 0; 
		return 1 if $_[0] == 1; 
		return _fib($_[0] - 2, 0, 1);
	}
	else {
		die "Entered is not a natural number";
	}
}
sub _fib { 
	my ($n, $x, $y) = @_; 
	if ($n) {
    	@_ = ( $n - 1, $y, $x + $y ); 
    	goto &_fib;
	}
	else {
		return $x + $y;
	} 
}
 say fib(shift @ARGV);