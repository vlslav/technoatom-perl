package Local::Source::Text;

use strict;
use warnings;

use parent 'Local::Source';


sub new {
	my ($class, %args) = @_;
	$args{counter} = 0;
    unless (exists $args{delimiter}) {
    	$args{delimiter} = "\n";
    }
    $args{strings} = [ split /$args{delimiter}/, delete $args{text} ];
    return bless \%args, $class;
}

1;