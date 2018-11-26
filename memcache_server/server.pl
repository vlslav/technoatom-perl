#!/usr/bin/perl

use strict;
use warnings;
use 5.016;
use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;
use Data::Dumper;

$|++;

my %memcached;
my $handlers;

tcp_server undef, 8888, sub {
	local $/ = "\r\n";
	my ($fh, $host, $port) = @_;
	say "Get connection from $host:$port";
	my $hdl; $hdl = AnyEvent::Handle->new(
		fh => $fh,
		on_error => sub {
			$hdl->destroy();
			say "Closed connection $host:$port";
		},
	);
	$handlers->{$fh} = $hdl;
	my $cb; $cb = sub {
		my $hdl = $_[0];
		if( my($cmd, $key, $flag, $exptime, $size) = $_[1] =~ /^(set|add)\s(\S+)\s(\d+)\s(\d+)\s(\d+)$/ ){
			$hdl->push_read( chunk => $size, sub {
					my $value = $_[1];
					$hdl->{rbuf} = '';
					if ($cmd eq "add") {
						if (exists $memcached{$key}) {
							$hdl->push_write("Key exists in memcached server\n");
						}
						else {
							$memcached{$key} = $value;
							if ($exptime) {
								my $t; $t = AnyEvent->timer(
		    						after    => $exptime,
		    						cb       => sub {
		   								say "Deleted key: $key, value: $memcached{$key}";
		       							delete $memcached{$key};
		       							undef $t;
		   							}				
   								);
							}
						}
					}
					elsif ($cmd eq "set") {
						if (exists $memcached{$key}) {
							$memcached{$key} = $value;
							if ($exptime) {
								my $t; $t = AnyEvent->timer(
		    						after    => $exptime,
		    						cb       => sub {
		   								say "Deleted key: $key, value: $memcached{$key}";
		       							delete $memcached{$key};
		       							undef $t;
		   							}				
   								);
							}
						}
						else {
							$hdl->push_write("Key exists in memcached server\n");
						}
					}
				}
			);
		}
		elsif ($_[1] =~ /^get\s(\S+)$/) {
			my $key = $1;
			if (exists $memcached{$key}) {
				my $length = length($memcached{$key});
				$hdl->push_write("VALUE $key 0 $length");
				$hdl->push_write("\r\n");
				$hdl->push_write($memcached{$key});
				$hdl->push_write("\r\n");
				$hdl->push_write("END\r\n");
			}
			else {
				$hdl->push_write("Key does not exist in memcached server\n");
			}
			$hdl->{rbuf} = '';
		}
		else {
			say "This memcached server has got only add, set, get commands";
		}
		$hdl->push_read(line => $cb);
	};
	$hdl->push_read(line => $cb);
};

AE::cv->recv;
