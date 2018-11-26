package Local::Reducer;

use strict;
use warnings;

=encoding utf8

=head1 NAME

Local::Reducer - base abstract reducer

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

=cut

sub reduce {}

sub reduced {
    my $self = shift;
    return $self->{reduced};
}

sub reduce_n {
    my ($self, $n) = @_;
    for (1..$n) {
        unless ($self->{source}->has_next) { 
        	last;
        }
        $self->reduce;
    }
    return $self->{reduced};
}

sub reduce_all {
    my $self = shift;
    while ($self->{source}->has_next) {
        $self->reduce;
    }
    return $self->{reduced};
}


1;
