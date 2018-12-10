#!/usr/bin/perl
use strict;
use warnings;
use 5.016;
use AnyEvent::Socket;
use AnyEvent::Handle;
use JSON::XS;
use Data::Dumper;
$| = 1;

my ($host, $port) = @ARGV;

my $w = AnyEvent->condvar;

unless (defined $host and defined $port) {
    die "Need host and port";
}

tcp_connect $host, $port, sub {
    my $fh = shift;
    my $hdl; $hdl = AnyEvent::Handle->new(
        fh => $fh,
        on_error => sub {
            $hdl->destroy();
            $w->send();
        },
        on_eof => sub {
            $hdl->destroy();
            $w->send();
        },
        on_read => sub {
            eval {
                print Dumper decode_json($_[0]->rbuf);
            } or do {
                say $_[0]->rbuf;
            };
            $_[0]->{rbuf} = '';    
        }
    );
    our $w; $w = AnyEvent->io(
            fh => \*STDIN,
            poll => "r",
            cb => sub {
                my $line = <STDIN>;
                $hdl->push_write($line);
            }
    );
};
$w->recv;
