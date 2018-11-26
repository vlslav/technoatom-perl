package Local::Source;

use strict;
use warnings;

sub next {
	my $self = shift;
    if ( $self->{counter} == scalar @{$self->{strings}} ) {
        return undef;
    }
    return $self->{strings}->[$self->{counter}++];
}

sub has_next {
	my $self = shift;
	return ($self->{counter} != (scalar @{$self->{strings}}) );
}

1;