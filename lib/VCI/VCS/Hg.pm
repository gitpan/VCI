package VCI::VCS::Hg;
use Moose;

use LWP::UserAgent;

use VCI::Util;

extends 'VCI';

our $VERSION = '0.0.0_1';

has 'x_ua' => (is => 'ro', isa => 'LWP::UserAgent', lazy => 1,
               default => sub { shift->build_x_ua });
has 'x_timeout' => (is => 'ro', isa => 'Int', default => sub { 60 });

sub build_x_ua {
    my $self = shift;
    return LWP::UserAgent->new(
        agent => __PACKAGE__ . " $VERSION",
        protocols_allowed => [ 'http', 'https'],
        timeout => $self->x_timeout);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

VCI::VCS::Hg - VCI Implementation for Mercurial (aka Hg)

=head1 DESCRIPTION

This is a "driver" for L<VCI> for the Mercurial version-control system.
You can find out more about Mercurial at L<http://www.selenic.com/mercurial/>.

For information on how to use VCI::VCS::Hg, see L<VCI>.

Currently VCI::VCS::Hg actually interacts with HgWeb, not directly with Hg
repositories. The only supported connections are C<http://> or C<https://>.

Local repositories are not yet supported.

=head1 CONNECTING TO A MERCURIAL REPOSITORY

For the L<repo|VCI/repo> argument to L<VCI/connect>, choose the actual
root of your hgweb installation.

For example, for C<http://hg.intevation.org/mercurial/stable>,
the C<repo> would be C<http://hg.intevation.org/>.

=head1 LIMITATIONS AND EXTENSIONS

These are limitations of VCI::VCS::Hg compared to the general API specified
in the C<VCI::Abstract> modules.

=head2 VCI::VCS::Hg

Also, you can only connect to hgweb installations. You cannot use ssh,
static-http, or local repositories. In the future we plan to support
local repositories, but ssh and static-http repositories will probably never
be supported. (Mercurial cannot work with them without cloning them, at which
point they are just a local repository.)

=head2 VCI::VCS::Hg::Directory

Specifying a revision for a directory will make C<contents> return
the contents of the directory at that time. However, all File and
Directory objects in those contents will have the revision identifier
of the parent Directory, regardless of whether they were actually modified
in that revision.

=head2 VCI::VCS::Hg::History

When directories were added/removed is not tracked by Mercurial, so
Directory objects never show up in a History.

=head2 VCI::VCS::Hg::Commit

Although Mercurial supports renames and copies of files, the hgweb
interface doesn't track renames and copies. So renames just look like
a file was deleted and then a file was added. Copies are simply
added files.

Mercurial doesn't track when directories were added or removed, so
Directory objects never show up in the contents of a Commit.

=head1 PERFORMANCE

On remote repositories, many operations can be B<extremely slow>. This
is because VCI::VCS::Hg makes many calls to the web interface, and any
delay between you an the remote server is magnified by the fact that
it happens over and over.

Working with the History of a Project involves using the RSS version of
the changelog from hgweb. The more items you allow hgweb to display in the
RSS version of the changelog, the faster VCI::VCS::Hg will be when working
with the history of a Project.

Getting the contents (or added/removed/modified) of a Commit can be
slow, as it has to access the web interface.