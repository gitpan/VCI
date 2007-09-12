package VCI::VCS::Svn;
use Moose;

use SVN::Client;

extends 'VCI';

our $VERSION = '0.1.2';

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
You can find out more about Subversion at L<http://subversion.tigris.org/>.

For information on how to use VCI::VCS::Svn, see L<VCI>.

=head1 CONNECTING TO A SUBVERSION REPOSITORY

For the L<repo|VCI/repo> argument to L<VCI/connect>, pass the same
URL that you'd pass to your SVN client, without the actual branch name.
That is, pass a URL to the very root of your repository.

For example, if I have a project called Foo that I store in
C<svn.domain.com/svn/repo/Foo> then the C<repo> would be
C<svn://svn.domain.com/svn/repo/>.

=head2 Local Repositories

Though Subversion itself doesn't allow relative paths in C<file://>
URLs, VCI::VCS::Svn does. So C<file://path/to/repo> will be interpreted
as meaning that you want the repo in the directory C<path/to/repo>.

In actuality, VCI::VCS::Svn converts that to an absolute path when
creating the Repository object, so using relative paths will fail
if you are in an environment where L<Cwd/abs_path> fails.

=head1 REQUIREMENTS

VCI::VCS::Svn requires at least Subversion 1.1, and the SVN::Client
perl modules that ship with Subversion must be installed.

=head1 LIMITATIONS AND EXTENSIONS

These are limitations of VCI::VCS::Svn compared to the general API specified
in the C<VCI::Abstract> modules.

=head2 VCI::VCS::Svn::Commit

=over

=item *

For C<added>, C<removed>, C<modified> and C<copied>, objects only
implement L<Committable|VCI::Abstract::Committable> without actually
being L<File|VCI::Abstract::File> or L<Directory|VCI::Abstract::Directory>
objects. This is due to a limitation in the current Subversion API.
(See L<http://subversion.tigris.org/issues/show_bug.cgi?id=1967>.)

=item *

C<copied> files always show up in C<added>, they never show up in C<modified>,
even if they were changed after they were copied. This is because
Subversion doesn't track that a copied file was modified after you copied
it.

This is also consitent with how they show up in C<as_diff> -- it looks like
a whole new file was added.

=item *

Subversion doesn't track if a moved file was modified after it was moved, only
that you copied a file and then deleted the old file. So moved files
show up in C<copied>, C<added>, and C<removed> instead of in C<moved>.

=back

=head1 PERFORMANCE

VCI::VCS::Svn performs well with both local and remote repositories, even
when there are large numbers of revisions in the repository. We use the
API directly in C (via SVN::Client), so there is no overhead of actually
using the C<svn> binary.

Some optimizations are not implemented yet, though, so certain operations
may be slow, such as searching commits by time. This should be easy to rectify
in a future version, particularly as I get some idea from users about how
they most commonly use L<VCI>.

=head1 SEE ALSO

L<VCI>

=head1 BUGS

VCI::VCS::Svn is very new, and may have significant bugs. The code is
alpha-quality at this point.

=head1 AUTHOR

Max Kanat-Alexander <mkanat@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Everything Solved, Inc.

L<http://www.everythingsolved.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.