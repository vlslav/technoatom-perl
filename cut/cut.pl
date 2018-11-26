#!/bin/perl

use strict;
use 5.016;
use warnings;
use Getopt::Long;
Getopt::Long::Configure ("bundling");

my ($fields, $separated, $delimeter) = ('', '', "\t");

GetOptions( 
	"f=s" => \$fields,
	"s" => \$separated,
	"d:s" => \$delimeter
);

my @fields_array = split /,/, $fields;

my $output_delim = $delimeter;
 
$delimeter = quotemeta substr $delimeter, 0, 1;

sub get_fields {
    my $line = shift;
    if (scalar @{$line} == 1) {
    	return $line;
    }
    my @temp;
    #фильтруем на наличие несуществующих колонок
    @temp = map {$_ - 1}  grep { ( $_ > 0 ) and ( $_ <= scalar @{$line} ) } @fields_array;
    #возвращаем только существующие
    return  [ @{$line}[@temp] ];
}


for (<STDIN>) {
    chomp;
    $_ = [ split /$delimeter/, $_ ];
    if ( not $separated or scalar @{$_} > 1 ) {
        $_ = get_fields($_);
        say join "$output_delim", @{$_};
    }
}
































