package VCI::Abstract::Commit;
use Moose;
use VCI::Util;

with 'VCI::Abstract::FileContainer';

# All of this crazy init_arg stuff means "coerce lazily, because
# DateTime is slow."
has 'time'       => (is => 'ro', isa => 'DateTime', coerce => 1, lazy => 1,
                     default => sub { shift->_time }, init_arg => '__time');
has '_time'      => (is => 'ro', isa => 'Defined', init_arg => 'time',
                     required => 1);

# XXX Git differentiates between Author and Committer, maybe this would be
#     a useful distinction for us?
has 'committer' => (is => 'ro', isa => 'Str', default => sub { '' });
has 'added'     => (is => 'ro', isa => 'ArrayOfCommittables', lazy => 1,
                    default => sub { shift->build_added });
has 'removed'   => (is => 'ro', isa => 'ArrayOfCommittables', lazy => 1,
                    default => sub { shift->build_removed });
has 'modified'  => (is => 'ro', isa => 'ArrayOfCommittables', lazy => 1,
                    default => sub { shift->build_modified });
has 'moved'     => (is => 'ro', isa => 'HashRef', lazy => 1,
                    default => sub{ shift->build_moved });
has 'copied'    => (is => 'ro', isa => 'HashRef', lazy => 1,
                    default => sub { shift->build_copied });
has 'revision'  => (is => 'ro', isa => 'Str', required => 1);
# XXX Probably should also have shortmessage, which can be the "subject"
#     for VCSes that store that, and the first line of the message for
#     VCSes that don't.
has 'message'   => (is => 'ro', isa => 'Str', default => sub { '' });

# XXX This should really be being enforced by FileContainer, but see the
#     note there.
has 'project'  => (is => 'ro', isa => 'VCI::Abstract::Project', required => 1);

sub build_added     { [] }
sub build_removed   { [] }
sub build_modified  { [] }
sub build_moved     { {} }
sub build_copied    { {} }

sub build_contents {
    my $self = shift;
    return [@{$self->added}, @{$self->removed}, @{$self->modified}];
}

# as_patch, as_bundle
# Also as_patch_binary, as_bundle_binary?
# And perhaps as_diff_from, as_bundle_from

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

VCI::Abstract::Commit - Represents a single atomic commit to the repository.

=head1 DESCRIPTION

Usually, when you modify a repository in version control, you modify many
files simultaneously in a single "commit" (also called a "checkin").

This object represents one of those commits in the history of a project.

Some version-control systems don't actually understand the idea of an
"atomic commit", but VCI does its best to figure out what files were
committed together and represent them all as one object.

A L<VCI::Abstract::Commit> implements L<VCI::Abstract::FileContainer>,
so all of FileContainer's methods are also available here.

B<Note>: Depending on how this object was constructed, it may or may
not actually contain information on all of the files that were committed
in this change. For example, when you use L<VCI::Abstract::File/history>, Commit
objects might only contain information about that single file. This is
due to the limits of various version-control systems.

=head1 METHODS

=head2 Accessors

These are all read-only.

=over

=item C<time>

A L<datetime|VCI::Util/DateTime> representing date and time of this commit.

On VCSes that don't understand atomic commits, this will be the time of
the I<earliest> commited file in this set.

=item C<committer>

A string identifying who committed this revision. That is, the username
of the committer, or their real name and email address (or something
similar). The format of this string is not guaranteed.

=item C<contents>

All of the items added, changed, or modified in this commit, as an arrayref
of L<VCI::Abstract::Committable> objects.

=item C<added>

Just the items that were added in this commit, as an arrayref of
L<VCI::Abstract::Committable> objects.

=item C<removed>

Just the items that were deleted in this commit, as an arrayref of
L<VCI::Abstract::Committable> objects.

=item C<modified>

The items that were modified (not added or removed, just changed) in this
commit, as an arrayref of L<VCI::Abstract::Committable> objects.

Any files that were L</moved> will have their I<new> names, not their old
names.

=item C<moved>

Some version-control systems understand the idea that a file can be renamed
or moved, not just removed and then added.

If a file was moved or renamed, it will show up in this accessor, which is a
hashref where the keys are the B<new> path and the value is the B<old> path,
as strings. (That might seem backwards until you realize that the I<new>
name is what shows up in L</modified>, so having keys on the I<new> name is
much more useful.)

The file will show up in L</modified> if it also had modifications
during this commit. (However, if there were no changes to the file other
than that it was moved, it won't show up in L</modified>.)

=item C<copied>

A hashref of objects that were copied from another file/directory, preserving
their history. The place we were copied from could have been in some other 
Project (and in rare cases, a completely different Repository, though VCI
might not track that it was copied in that case).

The keys are the name of the file as it is now, and the value is a
C<VCI::Abstract::Committable> that represents the object it was copied from.

Any item in C<copied> will also show up in C<modified> if it was changed
during this commit, and C<added> otherwise.

=item C<revision>

A string representing the unique identifier of this commit, according to
the version-control system.

For version-controls systems that don't understand atomic commits, this
will be some unique identifier generated by VCI. This identifier is
guaranteed to be stable--that is, you can use it to retrieve this commit
object from L<VCI::Abstract::Project/get_commit>.

Individual C<VCI::VCS> implementations will specify the format of their
revision IDs, if they are a VCS that doesn't have unique identifiers for
commits, or if there is any ambiguity about what exactly "revision id"
means for that VCS.

=item C<message>

The message that was entered by the committer, describing this commit.

=back

=head1 CLASS METHODS

=head2 Constructors

Usually you won't construct an instance of this class directly, but
instead, use various methods of L<VCI::Abstract::Project> to get
Commits out of the Project's History.

=over

=item C<new>

Takes all L</Accessors> as named parameters. The following fields are
B<required>: L</time>, L</revision>, and
L<project|VCI::Abstract::FileContainer/project>.

If L</committer> and L</message> aren't specified, they default to an
empty string.

=back