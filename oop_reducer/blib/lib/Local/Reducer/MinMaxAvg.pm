package Local::Reducer::MinMaxAvg;

use strict;
use warnings;
use Scalar::Util qw(looks_like_number);

use parent 'Local::Reducer';
    
sub new {
    my ($class, %args) = @_;
    $args{min} = delete $args{initial_value};
    $args{max} = $args{min};
    $args{avg} = $args{max};
    $args{sum} = 0;
    $args{count} = 0;
    return bless \%args, $class;
}


sub reduce_all {
    my $self = shift;

    while ($self->{source}->has_next) {
        $self->reduce;
    }
    return Local::Reducer::MinMaxAvg::Result->new(
        min => $self->{min},
        max => $self->{max},
        avg => $self->{avg},
        );
}
    
sub reduce_n {
    my ($self, $n) = @_;

    for (1..$n) {
        $self->reduce;
    }
    return Local::Reducer::MinMaxAvg::Result->new(
        min => $self->{min},
        max => $self->{max},
        avg => $self->{avg},
        );
}

sub reduce {
    my $self = shift;
    my $row_class = $self->{row_class};
    my $str = $row_class->new(str => $self->{source}->next);
    unless ($str) {
        return undef;
    }
    my $value = $str->get($self->{field}, 0);

    if (looks_like_number($value)) {
        if ($value > $self->{max}) {
            $self->{max} = $value;
        }
        unless ($self->{count}) {
            $self->{min} = $value;
        }
        if ($value < $self->{min}) {
            $self->{min} = $value;
        }

        $self->{count}++;
        $self->{sum} += $value;
        $self->{avg} = $self->{sum} / $self->{count};
    }
    else {
        return undef;
    }
    
}

package  Local::Reducer::MinMaxAvg::Result;

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}

sub get_min {
    my $self = shift;
    return $self->{min};
}

sub get_max {
    my $self = shift;
    return $self->{max};
}

sub get_avg {
    my $self = shift;
    return $self->{avg};
}


1;
