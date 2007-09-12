#!/usr/bin/perl
use strict;
use warnings;
use lib 't/lib';
use Cwd qw(cwd);
use Test::More;
use VCI;
use Support qw(test_vcs feature_enabled);
BEGIN { plan skip_all => "cvs not enabled" if !feature_enabled('cvs'); }
use IPC::Cmd;

#############################
# Constants and Subroutines #
#############################

use constant EXPECTED_CONTENTS => [qw(
    doc
    Doxyfile
    EmptyFile
    examples
    FileWithContents
    htom_dropdown.php
    htom_evaluable.php
    htom_fileinput.php
    htom_table.php
    htom_textarea.php
    newdir
    ts_picker
    doc/htom-logo.png
    examples/htom_debug_example.php
    examples/htom_example1.php
    examples/htom_table_example.php
    examples/img
    examples/img/htom.png
    newdir/EmptyFile
    newdir/NewFileInNewDir
    ts_picker/cal.gif
    ts_picker/next.gif
    ts_picker/prev.gif
    ts_picker/ts_picker.js
)];

use constant EXPECTED_COMMIT => {
    revision  => 6,
    message   => "This is the commit for testing VCI.\n"
                 . "And it has a two-line message.",
    committer => 'mkanat',
    time      => '2007-09-02T16:41:38',
    timezone  => '-0700',
    modified  => [qw(Doxyfile examples/htom_table_example.php)],
    added     => [qw(EmptyFile FileWithContents newdir/EmptyFile
                     newdir/NewFileInNewDir)],
    removed   => [qw(htom_action.php htom_alignment.php htom_attribute.php
                     htom_autoloader.php htom_button.php htom_checkbox.php
                     htom_container.php htom_controler.php htom_dateinput.php
                     htom_debug.php)],
    moved     => {},
    copied    => {},
    added_empty => { EmptyFile => 1, 'newdir/EmptyFile' => 1 },
};

use constant EXPECTED_FILE => {
    path     => 'examples/htom_debug_example.php',
    revision => '1.3',
    time     => '2007-09-03T01:40:30',
    timezone => '+0000',
    commits  => 3,
    last_revision  => '1.3',
    first_revision => '1.1',
};

sub setup_repo {
    eval { require LWP::UserAgent } || die "LWP::Useragent not installed";
    my $ua = LWP::UserAgent->new(timeout => 10,
                                 agent => 'vci-test/' . VCI->VERSION);

    my $response =
        $ua->mirror("http://vci.everythingsolved.com/repos/cvs/cvs-test-2007-09-02.tar.bz2",
                    'cvs-test.tar.bz2');
    if (!$response->is_success) {
        die $response->status_line;
    }
    
    system('bunzip2 ./cvs-test.tar.bz2') && die 'Failed to bunzip';
    system('tar -x -f ./cvs-test.tar') && die 'Failed to untar';
    unlink 'cvs-test.tar';
}

#########
# Tests #
#########

IPC::Cmd::can_run('cvs')
    || plan skip_all => 'cvs not installed or in the path';
IPC::Cmd::can_run('cvsps')
    || plan skip_all => 'cvsps not installed or in the path';

my $repo_success = eval {
    my $cwd = cwd();
    chdir 't/repos/cvs/' || die $!;
    setup_repo() if !-d 't/repos/cvs/CVSROOT';
    chdir $cwd || die "$cwd: $!"; 
};
$repo_success || plan skip_all => "Unable to create cvs testing repo: $@";

plan tests => 34;

test_vcs({
    type          => 'Cvs',
    repo_dir      => ':local:t/repos/cvs',
    project_name  => 'htom',
    mangled_name  => '/htom/',
    num_commits   => 9,
    expected_contents => EXPECTED_CONTENTS,
    expected_commit   => EXPECTED_COMMIT,
    diff_type     => 'VCI::VCS::Cvs::Diff',
    expected_file => EXPECTED_FILE,
});