#!/usr/bin/perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use VCI;
use Support qw(test_vcs feature_enabled);

#############################
# Constants and Subroutines #
#############################

use constant EXPECTED_CONTENTS => [qw(
    VCI
    VCI.pm
    VCI/Abstract
    VCI/Abstract/Commit.pm
    VCI/Abstract/Committable.pm
    VCI/Abstract/Directory.pm
    VCI/Abstract/File.pm
    VCI/Abstract/FileContainer.pm
    VCI/Abstract/History.pm
    VCI/Abstract/Project.pm
    VCI/Abstract/Repository.pm
    VCI/Util.pm
)];

use constant EXPECTED_COMMIT => {
    revision  => 3,
    message   => "Add more documentation, re-work Committable, move"
          . " VCI::Abstract::Util to just be VCI::Util (that makes more sense,"
          . " since the Utilities aren't abstract...) and move from using"
          . " Epochs to using DateTime objects.",
    committer => 'Max Kanat-Alexander <mkanat@es-compy>',
    time      => '2007-08-05T21:12:57',
    timezone  => '-0700',
    moved     => { 'VCI/Util.pm' => 'VCI/Abstract/Util.pm' },
    added     => [],
    removed   => [],
    copied    => {},
    modified  => [qw(VCI/Abstract/Comittable.pm VCI/Abstract/Commit.pm
                     VCI/Abstract/Repository.pm VCI/Util.pm)],
    added_empty => {},
};

use constant EXPECTED_FILE => {
    path     => 'VCI/Abstract/Repository.pm',
    revision => 6,
    time     => '2007-08-07T00:07:43',
    timezone => '-0700',
};

sub setup_repo {
    system("bzr init-repo --knit --no-trees t/repos/bzr");
    system("bzr branch -r10 http://bzr.everythingsolved.com/vci/trunk"
           . " t/repos/bzr/vci");
}

#########
# Tests #
#########

plan skip_all => "bzr not enabled" if !feature_enabled('bzr');

eval { setup_repo() if !-d 't/repos/bzr/.bzr'; 1; }
    || plan skip_all => "Unable to create bzr testing repo: $@";
    
plan tests => 28;

test_vcs({
    type          => 'Bzr',
    repo_dir      => 't/repos/bzr',
    project_name  => 'vci',
    mangled_name  => '/vci/',
    num_commits   => 10,
    expected_contents => EXPECTED_CONTENTS,
    expected_commit   => EXPECTED_COMMIT,
    diff_type     => 'VCI::Abstract::Diff',
    expected_file => EXPECTED_FILE,
});