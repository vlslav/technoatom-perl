package Local::Loop;

use strict;
use warnings;
use IO::Select;

our $timeout = 0.1;
our $loop_timeout = 1;
my $s = IO::Select->new();

my $buffers = {};
my @timers = (); 
my %fhs_read = ();
my %fhs_write = ();


my $looped = 1;


sub write_fh {
    my $fh = shift;
    my $cb = shift;
    $fhs_write{$fh} = $cb;
    $s->add($fh);
}

sub read_fh {
    my $fh = shift;
    my $cb = shift;
    $fhs_read{$fh} = $cb;
    $s->add($fh);
}

sub del_read_fh {
    my $fh = shift;
    delete $fhs_read{$fh};
    $s->remove($fh) unless exists $fhs_write{$fh};
}

sub del_write_fh {
    my $fh = shift;
    delete $fhs_write{$fh};
    $s->remove($fh) unless exists $fhs_read{$fh};
}

sub start_loop {
    die "Selector required" unless $s;
    $looped = 1;
    while ($looped) {
        my $start_loop = time();
        my @fhs = $s->can_read($timeout);
        for my $fh (@fhs) {
            if (exists $fhs_read{$fh}) {
                $fhs_read{$fh}->($fh);
            }
        }
        @fhs = $s->can_write($timeout);
        for my $fh (@fhs) {
            if (exists $fhs_write{$fh}) {
                $fhs_write{$fh}->($fh);
            }
        }
        my @ready_timers = @timers;
        @timers = ();
        for my $timer (@ready_timers) {
            if ($timer->{time} <= $start_loop) {
                $timer->{cb}->();
            }
            else {
                push @timers, $timer;
            }
        }
        if (time - $start_loop < $loop_timeout) {
            sleep(time - $start_loop);
        }
    }
}


1;