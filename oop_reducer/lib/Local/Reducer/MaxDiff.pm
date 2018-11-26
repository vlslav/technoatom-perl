package Local::Reducer::MaxDiff;

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
    unless ($str) { 
    	return undef; 
    }
    my $top = $str->get($self->{top}, 0);
    my $bottom = $str->get($self->{bottom}, 0);
    if (looks_like_number($bottom) && looks_like_number($top)) {
        if (abs($top - $bottom) > $self->{reduced}) {
            $self->{reduced} = abs($top - $bottom);
        }
    }
    else {
    	return undef;
    }
}
	

1;