#!/usr/bin/perl
use strict;
use warnings;
use lib 't/lib';
use Cwd qw(cwd);
use Test::More;
use VCI;
use Support qw(test_vcs feature_enabled);

#############################
# Constants and Subroutines #
#############################

use constant EXPECTED_CONTENTS => [qw(
    EmptyFile
    GQProtocol_BattleField2.inc.php
    GQProtocol_BattleField2142.inc.php
    GQProtocol_HalfLife.inc.php
    GQProtocol_SourceEngine.inc.php
    GQTemplate_BF2142_compact.inc.php
    GQTemplate_BF2_compact.inc.php
    GQTemplate_CSS_compact.inc.php
    GQTemplate_Dump.inc.php
    GQTemplate_FEAR_compact.inc.php
    License.txt
    License.txt2
    Moved
    NewFile
    emptydir
    newdir
    newdir/EmptyFile
    newdir/NewFile
)];

use constant EXPECTED_COMMIT => {
    revision  => 12,
    message   => "This is the commit for testing VCI.\n"
                 . "And it has a two-line message.",
    committer => 'mkanat',
    time      => '2007-09-03T06:46:21',
    timezone  => '+0000',
    modified  => [qw(GQProtocol_BattleField2.inc.php
                     GQProtocol_BattleField2142.inc.php)],
    added     => [qw(EmptyFile NewFile newdir/NewFile newdir/EmptyFile
                     emptydir License.txt2 Moved newdir)],
    removed   => [qw(GQProtocol_GameSpy.inc.php GQProtocol_GameSpy2.inc.php
                     GameQuery.php)],
    moved     => {},
    copied    => { 'License.txt2' => { 'License.txt' => 11   },
                   'Moved'        => { 'GameQuery.php' => 11 },
                 },
    added_empty => { EmptyFile => 1, 'newdir/EmptyFile' => 1, emptydir => 1,
                     newdir => 1 },
};

use constant EXPECTED_FILE => {
    path     => 'GQProtocol_SourceEngine.inc.php',
    revision => 11,
    time     => '2007-08-13T04:54:44',
    timezone => '+0000',
    size     => 11819,
    commits  => 3,
    last_revision  => '11',
    first_revision => '4',
};

sub setup_repo {
    eval { require LWP::UserAgent } || die "LWP::Useragent not installed";
    my $ua = LWP::UserAgent->new(timeout => 10,
                                 agent => 'vci-test/' . VCI->VERSION);

    my $response =
        $ua->mirror("http://vci.everythingsolved.com/repos/svn/svn-test-2007-09-02.tar.bz2",
                    'svn-test.tar.bz2');
    if (!$response->is_success) {
        die $response->status_line;
    }
    
    system('bunzip2 ./svn-test.tar.bz2') && die 'Failed to bunzip';
    system('tar -x -f ./svn-test.tar') && die 'Failed to untar';
    unlink 'svn-test.tar';
}

#########
# Tests #
#########

my $repo_success = eval {
    my $cwd = cwd();
    chdir 't/repos/svn/' || die $!;
    setup_repo() if !-d 't/repos/svn/db';
    chdir $cwd || die "$cwd: $!"; 
};
$repo_success || plan skip_all => "Unable to create svn testing repo: $@";

# If we don't do this, Module::Build will think that SVN is *always*
# disabled.
eval { require SVN::Core };

plan skip_all => "svn not enabled" if !feature_enabled('svn');

plan tests => 39;

test_vcs({
    type          => 'Svn',
    repo_dir      => 'file://t/repos/svn',
    num_projects  => 3,
    project_name  => 'trunk',
    mangled_name  => '/trunk/',
    num_commits   => 8,
    expected_contents => EXPECTED_CONTENTS,
    expected_commit   => EXPECTED_COMMIT,
    diff_type     => 'VCI::Abstract::Diff',
    copy_in_diff  => 1,
    expected_file => EXPECTED_FILE,
});