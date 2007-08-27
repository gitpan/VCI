package VCI::Abstract::File;
use Moose;

with 'VCI::Abstract::Committable';

has 'is_executable' => (is => 'ro', lazy => 1,
                        default => sub { shift->build_is_executable });

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

VCI::Abstract::File - A single file in the repository.

=head1 DESCRIPTION

This represents a file in the repository. It implements
L<VCI::Abstract::Committable>, so all of those methods are available on
a File in addition to the methods listed below.

=head1 METHODS

=head2 Accessors

These are methods you call to get information about a File. They are all
read-only--you cannot update a File's information using this interface.

=over

=item C<is_executable>

C<1> if this file is tagged as an executable by the VCS, C<0> if it is
not. If the VCS doesn't track this info, this returns C<undef>.

=back

=head1 CLASS METHODS

=head2 Constructors

Usually you won't construct an instance of this class directly, but
instead, use various methods of other modules that create File
objects by interacting with the L<Project|VCI::Abstract::Project>.

=over

=item C<new>

Takes all L</Accessors> of this class and L<VCI::Abstract::Committable>,
as named parameters. The following fields are B<required>: L</path>
and L</project>.

If you don't specify L</revision>, VCI assumes you want an object
representing the "latest" or "HEAD" revision of this File.

=back