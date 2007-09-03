#!/usr/bin/perl
use strict;
use warnings;

use lib 't/lib';
use Test::More;
use Support;

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

foreach my $vcs (@features) {
    my $vcs_modules = $modules{$vcs};
    SKIP: {
        skip "$vcs not enabled", scalar(@$vcs_modules)
            if !feature_enabled($vcs);
        use_ok($_) foreach @$vcs_modules;
    }
}
