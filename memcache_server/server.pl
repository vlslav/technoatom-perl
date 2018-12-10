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
my $MAX_SIZE = 1e+6;
my $MEMORY = 0;
my $MAX_MEMORY = 8e+9;
my @keys;


my $idle = AnyEvent->idle( cb => sub {
		my $count = 0;
		for (@keys) {
			if ($count++ <= 100) {
				my $temp = shift @keys;
				push @keys, $temp;
				if ($memcached{$temp}->[1] != 0 and $memcached{$temp}->[1] < time) {
					say "Deleted key: $temp, value: $memcached{$temp}->[0]";
					$MEMORY -= length($memcached{$temp}->[1]);
				    delete $memcached{$temp};
				    pop @keys;
				}
			}
			else {
				last;
			}
		}
	}
);

sub store {
	my ($hdl, $key, $exptime, $value_ref) = @_;
	if ($exptime >= 0) {
		$exptime += time if $exptime != 0;
		$memcached{$key} = [$$value_ref, $exptime];
		$MEMORY += length($$value_ref);
		$hdl->push_write("STORED\r\n");
	}
	else {
		$hdl->push_write("CLIENT_ERROR wrong exptime\r\n");
	}
}

tcp_server undef, 8888, sub {
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
			if ($size <= $MAX_SIZE) {
				$hdl->push_read( chunk => $size, sub {
						my $value_ref = \$_[1];
						$hdl->{rbuf} = '';
						if (exists $memcached{$key}) {
							if ($memcached{$key}->[1] < time and $memcached{$key}->[1] != 0) {
								$MEMORY -= length($memcached{$key}->[0]);
								say "Deleted key: $key, value: $memcached{$key}->[0]";
								delete $memcached{$key};
							}
						}
						if (exists $memcached{$key}) {
							if ($MEMORY + $size < $MAX_MEMORY) {
								store($hdl, $key, $exptime, $value_ref) if ($cmd eq "set");
								$hdl->push_write("EXISTS\r\n") if ($cmd eq "add");
							}
							else {
								$hdl->push_write("SERVER_ERROR (too many keys)\r\n");
							}
						}
						else {
							if ($MEMORY + $size + 2*length($key) < $MAX_MEMORY) {
								if ($cmd eq "add") {
									store($hdl, $key, $exptime, $value_ref);
									push @keys, $key;
								}
								$hdl->push_write("NOT STORED\r\n") if ($cmd eq "set");
							}
							else {
								$hdl->push_write("SERVER_ERROR (too many keys)\r\n");
							}
						}
					}
				);
			}
			else {
				$hdl->push_write("SIZE_ERROR\r\n");
			}
		}
		elsif ($_[1] =~ /^get\s(\S+)$/) {
			my $key = $1;
			if (exists $memcached{$key}) {
				if ($memcached{$key}->[1] > time or $memcached{$key}->[1] == 0){
					my $length = length($memcached{$key}->[0]);
					$hdl->push_write("VALUE $key 0 $length\r\n$memcached{$key}->[0]\r\nEND\r\n");
				}
				else {
					if ($memcached{$key}->[1] > 0) {
						say "Deleted key: $key, value: $memcached{$key}->[0]";
						$MEMORY -= length($memcached{$key}->[1]);
						delete $memcached{$key};
					}
					$hdl->push_write("Key does not exist in memcached server\r\n");
				}
			}
			else {
				$hdl->push_write("Key does not exist in memcached server\r\n");
			}
			$hdl->{rbuf} = '';
		}
		else {
			$hdl->push_write("ERROR (bad command)\r\n");
		}
		$hdl->push_read(line => $cb);
	};
	$hdl->push_read(line => $cb);
};

AE::cv->recv;


