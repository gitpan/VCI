#!/usr/bin/perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use VCI;
use Support qw(test_vcs feature_enabled);

use Carp; local $SIG{__DIE__} = \&Carp::confess;

#############################
# Constants and Subroutines #
#############################

use constant EXPECTED_CONTENTS => [qw(
Argh-Spec.txt  EmptyFile  Makefile  newdir   README
COPYING2       examples   New       NewFile  tests
.hgignore .hgtags

examples/2dec.agh examples/cat2.agh examples/EmptyFile examples/revert2.agh
examples/tricky1.agh examples/beer.agh  examples/cat2dec.agh
examples/hello.agh examples/revert.agh examples/cat1.agh examples/cat3.agh
examples/NewFile examples/tenhello.agh

newdir/EmptyFile  newdir/NewFile

tests/aargh-height-good.agh tests/argh-height-good.agh tests/jump.agh
tests/width-bad.agh tests/argh-height-bad.agh tests/conditional.agh
tests/run-tests.sh tests/width-good.agh
)];

use constant EXPECTED_COMMIT => {
    revision  => 'b56a898fdf90',
    message   => "This is the commit for testing VCI.\n"
                 . "And it has a two-line message.",
    committer => 'root@12.d1.5446.static.theplanet.com',
    time      => '2007-09-07T02:11:54',
    timezone  => '-0500',
    added     => [qw(Argh-Spec2.txt COPYING2 Moved NewFile README-COPIED
                     examples/NewFile newdir/NewFile)],
    removed   => [qw(argh-mode.el argh.c argh.lisp)],
    modified  => [qw(Argh-Spec.txt)],
    moved     => {},
    copied    => {},
    added_empty => {}
};

use constant EXPECTED_FILE => {
    path     => 'Makefile',
    revision => 'tip',
    time     => '2007-09-07T02:51:36',
    timezone => '-0500',
    size     => 865,
    commits  => 4,
    first_revision => 'd3f1ae8a1444',
    last_revision  => '626207473726',
};

#########
# Tests #
#########

plan skip_all => 'VCI_REMOTE_TESTS environment variable not set to 1'
    if !$ENV{VCI_REMOTE_TESTS};
plan skip_all => "hg not enabled" if !feature_enabled('hg');

plan tests => 39;

test_vcs({
    type          => 'Hg',
    repo_dir      => 'http://hg-test.vci.everythingsolved.com/2007-09-07/',
    project_name  => 'test-repo',
    mangled_name  => '/test-repo/',
    num_commits   => 23,
    expected_contents => EXPECTED_CONTENTS,
    expected_commit   => EXPECTED_COMMIT,
    diff_type     => 'VCI::VCS::Hg::Diff',
    copy_in_diff  => 1,
    expected_file => EXPECTED_FILE,
});