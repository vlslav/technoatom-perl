#!/usr/bin/env perl

use 5.016;
use warnings;
use Getopt::Long;
use Data::Dumper;
use List::MoreUtils qw(uniq);
use Scalar::Util qw(looks_like_number);

my @data = <STDIN>;
my @help;
unless(@ARGV) {
	print sort @data;
	exit;
}

my @lines;
my @columns;

for (@data) {
	push @lines, [split /\s+/, $_];
}

for my $i (0..$#{ $lines[0] }) {
	my @temp;
	for (0..$#lines) {
		if (defined $lines[$_][$i]) {
			push @temp, $lines[$_][$i];
		}
		else {
			push @temp, '';
		}
	}
	push @columns, [@temp];
	$#temp = -1;
}

#print Dumper \@lines;
#print Dumper \@columns;


my @key = '';
my $numeric = '';
my $unique = '';
my $reverse = '';


GetOptions( "-k=i" => \@key, 
			"-n" => \$numeric,
			"-u" => \$unique,
			"-r" => \$reverse,
			);


if ($#key) {
	$key[0] = 1;
	$key[1] -= 1;
	key();
}

if ($numeric && !$key[0]) {
	numeric(0);
};
if ($unique && !$key[0] && !$numeric && !$reverse) { 
	unique();
};
if ($reverse && !$key[0] && !$numeric) { 
	rvrs();
};

print @help;

sub key {
	if ($numeric) {
		numeric($key[1]);
	}
	else {
		my @sorted_columns = sort @{ $columns[ $key[1] ] };
		my @idx;
		for my $i (@sorted_columns) {
			push @idx, grep { ${ $columns[ $key[1] ] }[$_] eq $i } 0..$#{ $columns[ $key[1] ] };
		}
		@idx = uniq @idx;
		for (@idx) {
			push @help, $data[ $_ ];
		}
		if ($unique) {
			@help = uniq @help;
		}
		if ($reverse) {
			@help = reverse @help;
		}
	}
}



sub numeric {
	my $column_number = shift;
	my @numbers = grep { looks_like_number($_) } @{ $columns[ $column_number ] };
	@numbers = sort { $a <=> $b } @numbers;
	my $i = 0;
	for ( @{ $columns[ $column_number ] } ) {
		if (!looks_like_number($_)) {
			push @help, $data[ $i ];
		}
		$i++;
	}
	my @idx;
	for my $j (@numbers) {
		push @idx, grep { ${ $columns[ $column_number ] }[$_] eq $j } 0..$#{ $columns[ $column_number ] };
	}
	@idx = uniq @idx;
	for (@idx) {
		push @help, $data[ $_ ];
	}
	if ($reverse) {
		@help = reverse @help;
	}
	if ($unique) {
		@help = uniq @help;
	}

}


sub unique {
	@data = sort @data;
	@data = uniq @data;
	if ($reverse) { @data = reverse @data };
	@help = @data;
}

sub rvrs {
	@data = sort @data;
	@data = reverse @data;
	@help = @data;
}
