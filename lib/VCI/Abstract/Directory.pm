package VCI::Abstract::Directory;
use Moose;

with 'VCI::Abstract::Committable', 'VCI::Abstract::FileContainer';

# Because composed roles don't call BUILD, this is in all objects that
# implment Committable.
sub BUILD { shift->_no_time_without_revision; }

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

VCI::Abstract::Directory - A directory in the repository.

=head1 DESCRIPTION

This represents a directory, which can contain other directories and files.

L<VCI::Abstract::Directory> implements L<VCI::Abstract::Committable>
and L<VCI::Abstract::FileContainer>, so it has all of the methods
available there, in addition to any methods listed in this documentation.

=head1 METHODS

=head2 Accessors

All these accessors are read-only.

=over

=item C<name>

In addition to what's specified in L<VCI::Abstract::Committable>:

If this is the root directory of the project, this will just be an empty
string.

=item C<path>

In addition to what's specified in L<VCI::Abstract::Committable>:

Root directories always have an "empty" L<Path|VCI::Util/Path>. That is,
the path is an empty string.

=back

=head1 CLASS METHODS

=head2 Constructors

Usually you won't construct an instance of this class directly, but
instead, use various methods of other modules that create Directory
objects by interacting with the L<Project|VCI::Abstract::Project>.

=over

=item C<new>

Takes all L</Accessors> of this class, L<VCI::Abstract::Committable>,
and L<VCI::Abstract::FileContainer> as named parameters. The following
fields are B<required>: L</path> and
L<project|VCI::Abstract::FileContainer/project>.

If you don't specify L<revision|VCI::Abstract::Committable/revision>, VCI
assumes you want an object representing the "latest" or "HEAD" revision of
this Directory.

=back