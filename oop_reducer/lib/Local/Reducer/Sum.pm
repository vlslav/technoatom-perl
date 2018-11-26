package Local::Reducer::Sum;

use strict;
use warnings;
use Scalar::Util qw(looks_like_number);

use parent 'Local::Reducer';
	
sub new {
		my ($class, %args) = @_;
		$args{reduced} = delete $args{initial_value};
		return bless \%args, $class;
}


sub reduce {
	my $self = shift;
	my $row_class = $self->{row_class};
	my $str = $row_class->new(str => $self->{source}->next);
	my $value;
	if (defined $str) {
		$value = $str->get($self->{field}, 0);
	}
	else {
		return undef;
	}
	if (looks_like_number($value)){
		return $self->{reduced} += $value;
	}
	else {
		return undef;
	}
}

1;