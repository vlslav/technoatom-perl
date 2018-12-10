#!/usr/bin/env perl

use strict;
use warnings;
use lib './lib';
use IO::Select;
use IO::Socket::INET;
use Time::HiRes qw/time/;
use Local::Loop;
use JSON::XS;
use Getopt::Long;
use Data::Dumper;
my $n;

GetOptions(
    "n=i" => \$n,
);


unless (defined $n) {
    die qq/Enter the number of stored records in the form "- n 100500"/;
}

my $server = IO::Socket::INET->new(
    LocalAddr => '127.0.0.1',
    LocalPort => '8899',
    Listen => 1,
    ReusePort => 1,
) or die "Cant start server on port 8899: $!";

my %all_fh = ();
my %name_fh;
my %stream_fh;
my %type_fh;
my %msg_type;
my %msg_name;
my @all_messages;


Local::Loop::read_fh($server, sub {
    my $fh = shift;
    my $new_client = $fh->accept();
    warn "New connection";
    $all_fh{$new_client} = $new_client;
    Local::Loop::read_fh($new_client, sub {
        my $fh = shift;
        my $buffer = '';
        if (sysread($fh, $buffer, 1024)) {
            eval {
                my $request = decode_json($buffer);
                if (defined $request->{stream} and $request->{stream} eq "in" and exists $request->{name}) {
                    unless (exists $stream_fh{$fh}) {
                        $stream_fh{$fh} = "in";
                        $name_fh{$fh} = $request->{name};
                        Local::Loop::write_fh($fh, sub {
                                my $fh = shift;
                                syswrite($fh, "Connected in feeder mode\n", 1024);
                                Local::Loop::del_write_fh($fh);
                            }
                        );
                    }
                    else {
                        Local::Loop::write_fh($fh, sub {
                                my $fh = shift;
                                syswrite($fh, "The connection has been established\n", 1024);
                                Local::Loop::del_write_fh($fh);
                            }
                        );
                    }
                }
                elsif (exists $request->{type} and exists $request->{msg}) {
                    if ($stream_fh{$fh} eq "in") {
                        if (@all_messages == $n) {
                            my $msg = shift @all_messages;
                            delete $msg_name{$msg};
                            delete $msg_type{$msg};
                        }
                        push @all_messages, $request->{msg};
                        $msg_type{$request->{msg}} = $request->{type};
                        $msg_name{$request->{msg}} = $name_fh{$fh};
                        for (grep {$_ ne $fh} keys %all_fh) {
                            if (defined $type_fh{$_} and $type_fh{$_} eq $request->{type}) {
                                Local::Loop::write_fh($_, sub {
                                        my $fh = shift;
                                        my $response = {
                                            feeder => $msg_name{$request->{msg}},
                                            type   => $request->{type},
                                            msg    => $request->{msg},
                                        };
                                        syswrite($fh, encode_json($response), 1024);
                                        Local::Loop::del_write_fh($fh);
                                    }
                                );
                            }
                        }
                    }
                    else {
                        Local::Loop::write_fh($_, sub {
                                my $fh = shift;
                                syswrite($fh, qq/You are in reader mode and cannot write messages\n/, 1024);
                                Local::Loop::del_write_fh($fh);
                            }
                        );
                    }
                }
                elsif ($request->{stream} eq "out" and exists $request->{type}) {
                    unless (exists $stream_fh{$fh}) {
                        $stream_fh{$fh} = "out";
                        $type_fh{$fh} = $request->{type};
                        Local::Loop::write_fh($fh, sub {
                                my $fh = shift;
                                syswrite($fh, "Connected in reader mode\n", 1024);
                                Local::Loop::del_write_fh($fh);
                            }
                        );
                        
                        Local::Loop::write_fh($fh, sub {
                                my $fh = shift;
                                $fh->autoflush(1);
                                for my $msg (@all_messages) {
                                    if ($msg_type{$msg} eq $type_fh{$fh}) {
                                        my $response = {
                                            feeder => $msg_name{$msg},
                                            type   => $request->{type},
                                            msg    => $msg,
                                        };
                                        syswrite($fh, encode_json($response), 1024);
                                    }
                                }
                                Local::Loop::del_write_fh($fh);
                            }
                        );   
                    }
                    else {
                        Local::Loop::write_fh($fh, sub {
                                my $fh = shift;
                                syswrite($fh, "The connection has been established\n", 1024);
                                Local::Loop::del_write_fh($fh);
                            }
                        );
                    }
                }
                else {
                    Local::Loop::write_fh($fh, sub {
                            my $fh = shift;
                            syswrite($fh, "Connected in reader mode\n", 1024);
                            Local::Loop::del_write_fh($fh);
                        }
                    );
                }
            1;
            } or do {
                Local::Loop::write_fh($fh, sub {
                        my $fh = shift;
                        my $string = "Please, note the protocol\n";
                        syswrite($fh, $string, 1024);
                        Local::Loop::del_write_fh($fh);
                    }
                );
            }
        }
        else {
            Local::Loop::del_read_fh($fh);
            close($fh);
            warn "Connection closed";
        }
    });
});

Local::Loop::start_loop();
warn "End loop";

