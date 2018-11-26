#!/bin/perl

use strict;
use 5.016;
use warnings;
use Getopt::Long;
use Data::Dumper;
Getopt::Long::Configure ("bundling");

my ($after, $before,
	$radius, $count,
	$ignore_case, $invert, 
	$fixed, $line_num
	) = (0, 0, 0, 0, 0, 0, 0, 0);

my @result;

GetOptions( 
	"A=i" => \$after,
	"B=i" => \$before,
	"C=i" => \$radius,
	"c" => \$count,
	"i" => \$ignore_case,
	"v" => \$invert,
	"F" => \$fixed,
	"n" => \$line_num,
);

if (not defined $ARGV[0]) {
	die "Need pattern\n";
}
my $pattern = $ARGV[0];

if ($radius) {
	$after = $before = $radius;
}

if ($fixed) {
	$pattern = quotemeta($pattern);
}

sub comp {
	if ($ignore_case) {
		return (($_[0] =~ qr/$_[1]/i) xor $invert);
	}
	else {
		return (($_[0] =~ $_[1]) xor $invert);
	}
}



my %lines_with_number;
my $count_after_match = 0;
my $flag;
my $counter = 0;

my $number = 0;

for (<STDIN>) {
	chomp;
	++$number;
	if (comp($_, $pattern)) {
        if ( $count_after_match > $before and ($after or $before) ) { 
        	say "--";
        }
        for (sort {$a <=> $b} keys %lines_with_number) {
        	say $lines_with_number{$_};
        }
        undef %lines_with_number;
        if (not $count) {
        	say ($number x $line_num . ":" x $line_num . $_);
        }
        ++$counter if ($count);
        $flag = 1;
        $count_after_match = 0;
    }
    elsif (not $count) {
        if ( $flag ) { 
        	++$count_after_match;
        }
        $lines_with_number{$number} = $number x $line_num . "-" x $line_num . $_;
        if ( $count_after_match <= $after and $count_after_match > 0 ) {
        	say $lines_with_number{$number};
        }
    }

    if (scalar keys %lines_with_number > $before) {
	    for (sort {$a <=> $b} keys %lines_with_number) {
	    	delete $lines_with_number{$_};
	    	last;
	    }
    }
}

say $counter if ($count);






