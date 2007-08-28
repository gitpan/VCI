package VCI::Abstract::FileContainer;
use Moose::Role;

has 'contents' => (is => 'ro', isa => 'ArrayOfCommittables', lazy => 1,
                   default => sub { shift->build_contents });
has 'contents_history' => (is => 'ro', isa => 'VCI::Abstract::History',
                           lazy => 1,
                           default => sub { shift->build_contents_history });

# Unfortunately we can't currently enforce this, because Moose throws an
# error about attribute conflicts for a Directory, which is both a Committable
# and a FileContainer.
#has 'project'  => (is => 'ro', isa => 'VCI::Abstract::Project', required => 1);

# Unfortunately Moose is a little dumb about Roles sometimes, and requires
# our *abstract* classes to implement these, instead of our subclasses. So
# we can't really require them.
#requires 'build_contents';

sub build_contents_history {
    my $self = shift;
    my @histories = map {$_->history} @{$self->contents};
    return $self->project->repository->vci->history_class->union(
        histories => \@histories, project => $self->project);
}

1;

__END__

=head1 NAME

VCI::Abstract::FileContainer - Anything that can contain a
File or Directory.

=head1 DESCRIPTION

This is a L<Moose::Role> that represents anything that can hold files.
Usually that's a L<VCI::Abstract::Directory>.

=head1 METHODS

=head2 Accessors

These accessors are all read-only.

=over

=item C<contents>

An arrayref of L<VCI::Abstract::Committable> objects that we contain.
The order is not guaranteed.

=item C<contents_history>

The L<VCI::Abstract::History> of all the items in this container. The History
will contain information about all of the items inside the container, but
possibly won't contain information about anything outside of the container.

This does not include the history of the item itself, if the item itself
has a history. (That is, if this item is also a L<VCI::Abstract::Committable>,
you should use the C<history> method to get information about this specific
item.)

=item C<project>

The L<VCI::Abstract::Project> that this FileContainer belongs to.

=back

=head1 SEE ALSO

B<Implementors>: L<VCI::Abstract::Directory> and L<VCI::Abstract::Commit>