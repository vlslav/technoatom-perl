package Local::Row::Simple;

use strict;
use warnings;

use parent 'Local::Row';

sub new {
	my ($class, %args) = @_;
	my @temp = split /,/, $args{str};
	for (@temp) {
		if ( !($_ =~ /^[^:,]+:{1}[^:,]+$/) ) {
			return undef;
		}
	}
	delete $args{str};
	%args =  map { split /:/, $_ } @temp ;
	return bless \%args, $class;
}

1;