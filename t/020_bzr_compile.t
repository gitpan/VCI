#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use lib qw(t/lib);
use Support qw(feature_enabled all_modules);

plan skip_all => "bzr not enabled" if !feature_enabled('bzr');

my @vcs_modules = all_modules("lib/VCI/VCS/Bzr");
push(@vcs_modules, "VCI::VCS::Bzr");
plan tests => scalar(@vcs_modules);
use_ok($_) foreach @vcs_modules;