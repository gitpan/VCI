#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Support qw(feature_enabled all_modules);

# If we don't do this, Module::Build will think that SVN is *always*
# disabled.
eval { require SVN::Core };

plan skip_all => "svn not enabled" if !feature_enabled('svn');

my @vcs_modules = all_modules("lib/VCI/VCS/Svn");
push(@vcs_modules, "VCI::VCS::Svn");
plan tests => scalar(@vcs_modules);
use_ok($_) foreach @vcs_modules;