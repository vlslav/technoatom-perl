package Local::Source::Array;

use strict;
use warnings;

use parent 'Local::Source';
	
sub new {
    my ($class, %args) = @_;
    $args{counter} = 0;
    $args{strings} = delete $args{array};
    return bless \%args, $class;
}


1;