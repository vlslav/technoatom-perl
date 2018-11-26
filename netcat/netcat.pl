#!/usr/bin/perl -w

use 5.016;
use IO::Socket;
use warnings;
use Getopt::Long;

my $udp;

GetOptions( "u" => \$udp );
my ($host, $port) = @ARGV;


my $remote = IO::Socket::INET->new(
	Proto    => $udp ? "udp" : "tcp",
	PeerAddr => "$host",
	PeerPort => "$port",
) or die "can't connect to $host:$port\n";


while (<STDIN>) { 
	$remote->send($_) or die "can't send $!";
}

$remote->recv( my $data, 1024 );
print $data;


close($remote);