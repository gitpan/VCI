#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

my @modules = glob 'VCI/Abstract/*.pm';
@modules = map { s|/|::|g; s|.pm$||; $_ } @modules;
push(@modules, 'VCI', 'VCI::Util');
plan tests => scalar(@modules);
use_ok($_) foreach @modules;
