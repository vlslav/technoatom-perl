#!/usr/bin/perl
use warnings;
use strict;
use feature 'say';

use Cache::Memcached::Fast;

my $cache = Cache::Memcached::Fast->new({servers => ["127.0.0.1:8888"]});

$cache->add("key1", 1);
say $cache->get("key1");
$cache->set("key1", 2, 3);
say $cache->get("key1");