#!/usr/bin/env perl

use 5.016;
use warnings;
# Решето Эратосфена.
sub prime {
	my ($n) = @_;
	if (int $n == $n && $n > 0) {
		my @Array = ();
		# Первые два значения массива заполняем единицами,
		# потому что эти значения соответствуют 0 и 1, а они не простые
		push @Array, 0, 0;
		for (2 .. $n) {
			push @Array, 1;
		}
		for (2 .. $n) {
			if ($Array[$_] == 1) {
				for (my $l = $_ ** 2; $l <= $n; $l += $_) {
					$Array[$l] = 0;
				}
			}
		}

		for (2 .. $n) {
			if ($Array[$_] == 1) {
				say "$_";
			}
		}
	}
	else {
		die "Entered is not a natural number";
	}
}


prime(@ARGV);
