package VCI::VCS::Cvs;
use Moose;
use MooseX::Method;
extends 'VCI';

use Cwd;
use IPC::Cmd;

use VCI::VCS::Cvs::Repository;

our $VERSION = '0.0.2';

has 'x_cvsps' => (is => 'ro', isa => 'Str', lazy => 1,
                  default => sub { shift->build_x_cvsps });
has 'x_cvs' => (is => 'ro', isa => 'Str', lazy => 1,
                default => sub { shift->build_x_cvs });

sub build_x_cvsps {
    my $cmd = IPC::Cmd::can_run('cvsps')
        || confess('Could not find "cvsps" in your path');
    return $cmd;
}

sub build_x_cvs {
    my $cmd = IPC::Cmd::can_run('cvs')
        || confess('Could not find "cvs" in your path');
    return $cmd;
}

method 'x_do' => named (
    args    => { isa => 'ArrayRef', required => 1 },
    fromdir => { isa => 'Str', default => '.' },
) => sub {
    my ($self, $params) = @_;
    my $fromdir = $params->{fromdir};
    my $args    = $params->{args};
    
    my $old_cwd = cwd();
    chdir $fromdir;
    my ($success, $errorcode, $all, $stdout, $stderr) =
        IPC::Cmd::run(command => [$self->x_cvs, '-f', @$args]);
    chdir $old_cwd;

    my $full_command = $self->x_cvs . ' ' . join(' ', @$args);
    if (!$success) {
        my $err_string = join('', @$stderr);
        chomp($err_string);
        confess("$full_command failed: $err_string");
    }
    
    my $output = join('', @$all);
    if ($self->debug) {
        print STDERR "Command: $full_command\n",
            "From: $fromdir\n",
            "Exit Code: $errorcode\n",
            "Results: $output";
    }
    return $output;
};

1;

__END__

=head1 NAME

VCI::VCS::Cvs - The CVS implementation of VCI

=head1 DESCRIPTION

This is a "driver" for L<VCI> for the CVS (Concurrent Versioning System)
version-control system. You can find out more about CVS at
L<http://www.nongnu.org/cvs/>.

For information on how to use VCI::VCS::Cvs, see L<VCI>.

=head1 CONNECTING TO A CVS REPOSITORY

For the L<repo|VCI/repo> argument to L<VCI/connect>, choose what you
would put in the C<CVSROOT> environment variable.

The constructor also takes two additional, optional parameters:

=over

=item C<x_cvs>

The path to the "cvs" binary on your system. If not specified, we will
search your C<PATH> and throw an error if C<cvs> isn't found.

=item C<x_cvsps>

The path to the "cvsps" binary on your system. If not specified, we will
search your C<PATH> and throw an error if C<cvsps> isn't found.

=back

=head1 REQUIREMENTS

In addition to the Perl modules listed for CVS Support when you install
L<VCI>, VCI::VCS::Cvs requires that the following things be installed
on your system:

=over

=item cvs

The C<cvs> client program, at least version 1.11. You can get this at
L<http://www.nongnu.org/cvs> for *nix systems and
L<http://www.cvsnt.org/> for Windows systems.

=item cvsps

This is a program that interacts with CVS to figure out what files were
committed together, since CVS doesn't normally track that information,
and VCI needs that information.

You can get it from L<http://www.cobite.com/cvsps/>. (Windows users
have to use Cygwin to run cvsps, which you can get from
L<http://www.cygwin.com/>.)

=back

=head1 REVISION IDENTIFIERS

cvsps groups file commits that are close together in time and have the same
message into "PatchSets". Each of these PatchSets is given a unique,
integer identifier.

Since VCI::VCS::Cvs uses cvsps, the revision identifiers on Commit objects
will be these PatchSet ids.

For File objects, the revision identifiers will be the actual revision
identifier as returned by CVS for that file. For example C<1.1>, etc.

For Directory objects, the revision identifier is currently always C<HEAD>.

=head1 LIMITATIONS AND EXTENSIONS

=over

=item *

Currently VCI doesn't understand the concept of "branches", so you are
always dealing with the C<HEAD> branch of a project. This will change
in the future so that VCI can access branches of projects.

=item *

cvsps needs to write to the C<HOME> directory of the current user,
you must have write access to that directory in order to interact
with the History of a Project.

=item *

VCI::VCS::Cvs has to write files to your system's temporary
directory (F</tmp> on *nix systems), and many operations will fail
if it cannot. It uses the temporary directory returned by
L<File::Spec/tmpdir>.

=item *

If your program dies during execution, there is a chance that
directories named like F<vci.cvs.XXXXXX> will be left in your temporary
directory. As long as no instance of VCI is currently running, it should
be safe to delete these directories.

=back

In addition, here are the limitations of specific modules compared to the
general API specified in the C<VCI::Abstract> modules:

=head2 VCI::VCS::Cvs::Repository

C<get_project> doesn't support modules yet, only directory names in
the repository. Using a module name might work, but operations on that
Project are likely to then fail.

=head2 VCI::VCS::Cvs::Commit

CVS doesn't track the history of a Directory, so Directory objects will
never show up in the added, removed, modified, or contents of a Commit.

=head2 VCI::VCS::Cvs::Directory

=over

=item *

For the C<time> accessor, we return the time of the most-recently-modified
file in this directory. If there are no files in the directory, we return
a time that corresponds to C<time() == 0> on your system, probably January
1, 1970 00:00:00. Currently this is a fairly slow operation, but it may be
optimized in the future.

=item *

All Directory objects have a revision of C<HEAD>, even if you get
them through the C<parent> accessor of a File.

=item *

If you manually create a Directory with a revision other than C<HEAD>,
the L<contents|VCI::Abstract::FileContainer/contents> will be incorrect.

=back

=head1 PERFORMANCE

VCI::VCS::Cvs performs fairly well, although it may be slower on projects
that have lots of files in one directory, or very long histories.

Working with a local repository will always be faster than working with
a remote repository. For most operations, the latency between you and
the repository is far more important than the bandwidth between you and
the repository.
