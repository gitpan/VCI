#!/usr/bin/perl
use strict;
use warnings;

use lib 't/lib';
use Test::More;
use AllModules;

BEGIN {
    eval "use Module::Build 0.26";
    plan skip_all => "This test requires Module::Build 0.26." if $@;
}

my @features = qw(bzr svn hg git cvs);

my %modules;
my $tests = 0;
foreach my $vcs (@features) {
    my $mod_name = ucfirst($vcs);
    my @vcs_modules = all_modules("lib/VCI/VCS/$mod_name");
    push(@vcs_modules, "VCI::VCS::$mod_name");
    $tests += scalar(@vcs_modules);
    $modules{$vcs} = \@vcs_modules;
}

plan tests => $tests;

# If we don't do this, Module::Build will think that SVN is *always*
# disabled.
eval { require SVN::Core };

my %feature_enabled;
if(my $build = eval { Module::Build->current; }) {
    $feature_enabled{$_} = $build->feature($_) foreach @features;
}
else {
    diag("Not inside a build, assuming all features are enabled.");
    $feature_enabled{$_} = 1 foreach @features;
}

foreach my $vcs (@features) {
    my $vcs_modules = $modules{$vcs};
    SKIP: {
        skip "$vcs not enabled", scalar(@$vcs_modules)
            if !$feature_enabled{$vcs};
        use_ok($_) foreach @$vcs_modules;
    }
}
