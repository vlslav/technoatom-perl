#!/usr/bin/perl

use strict;
use warnings;
use 5.016;
use AnyEvent::Socket;
use AnyEvent::Handle;

my ($host, $port) = @ARGV;
unless (defined $host and defined $port) {
    die "Need host and port";
}
tcp_connect $host, $port, sub {
    my $fh = shift;

    my $hdl; $hdl = AnyEvent::Handle->new(
        fh => $fh,
        on_error => sub {
            $hdl->destroy();
        },
        on_read => sub {
            $hdl->push_read(line => sub {
                say $_[1];
            });
        },
    );
    our $w; $w = AnyEvent->io(
            fh => \*STDIN,
            cb => sub {
                my $line = <STDIN>;
                $hdl->push_write($line);
            }
        );
};
AE::cv->recv;