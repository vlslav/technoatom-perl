#!/usr/bin/env perl

use 5.016;
use warnings;

sub count {
	if (@ARGV == 2) {
		my ($string, $substring) = @_;
		my $index = index($string, $substring);
		if ($index != -1) {
			print $index . "\n";
			print substr($string, $index) . "\n";
		}
		else {
			warn "Not found";
			exit 1;
		}
	}
	elsif (@ARGV > 2) {
		die "Many arguments\n";
	}
	else {
		die "Not enough arguments\n";
	}
}
count(@ARGV);
