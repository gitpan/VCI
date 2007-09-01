package VCI::VCS::Svn;
use Moose;

use SVN::Client;

extends 'VCI';

our $VERSION = '0.0.3';

has 'x_client' => (is => 'ro', isa => 'SVN::Client', lazy => 1,
                   default => sub { shift->build_x_client });

sub build_x_client {
    my $self = shift;
    return SVN::Client->new(config => {});
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

VCI::VCS::Svn - The Subversion implementation of VCI

=head1 DESCRIPTION

This is a "driver" for L<VCI> for the Subversion version-control system.
You can find out more about Subversion at L<http://subversion.tigris.org>.

For information on how to use VCI::VCS::Svn, see L<VCI>.

=head1 CONNECTING TO A SUBVERSION REPOSITORY

For the L<repo|VCI/repo> argument to L<VCI/connect>, pass the same
URL that you'd pass to your SVN client, without the actual branch name.
That is, pass a URL to the very root of your repository.

For example, if I have a project called Foo that I store in
C<svn.domain.com/svn/repo/Foo> then the C<repo> would be
C<svn://svn.domain.com/svn/repo/>.

=head1 REQUIREMENTS

VCI::VCS::Svn requires at least Subversion 1.1, and the SVN::Client
perl modules that ship with Subversion must be installed.

=head1 LIMITATIONS AND EXTENSIONS

These are limitations of VCI::VCS::Svn compared to the general API specified
in the C<VCI::Abstract> modules.

=head2 VCI::VCS::Svn::Commit

For C<added>, C<removed>, C<modified> and C<copied>, objects only
implement L<Committable|VCI::Abstract::Committable> without actually
being L<File|VCI::Abstract::File> or L<Directory|VCI::Abstract::Directory>
objects. This is due to a limitation in the current Subversion API.
(See L<http://subversion.tigris.org/issues/show_bug.cgi?id=1967>.)

=head1 PERFORMANCE

VCI::VCS::Svn performs well with both local and remote repositories, even
when there are large numbers of revisions in the repository. We use the
API directly in C (via SVN::Client), so there is no overhead of actually
using the C<svn> binary.

Some optimizations are not implemented yet, though, so certain operations
may be slow, such as searching commits by time. This should be easy to rectify
in a future version, particularly as I get some idea from users about how
they most commonly use L<VCI>.
