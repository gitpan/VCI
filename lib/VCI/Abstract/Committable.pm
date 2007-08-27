package VCI::Abstract::Committable;
use Moose::Role;
use VCI::Util;

has 'history'        => (is => 'ro', isa => 'VCI::Abstract::History', lazy => 1,
                         default => sub { shift->build_history });

has 'first_revision' => (is => 'ro', does => 'VCI::Abstract::Committable',
                         lazy => 1,
                         default => sub { shift->build_first_revision });
                                          
has 'last_revision'  => (is => 'ro', does => 'VCI::Abstract::Committable',
                         lazy => 1,
                         default => sub { shift->build_last_revision });

has 'revision'   => (is => 'ro', lazy => 1,
                     default => sub { shift->build_revision });
# All of this crazy init_arg stuff means "coerce lazily, because it's
# slow to make thousands of DateTime and Path::Abstract objects."
has 'time'       => (is => 'ro', isa => 'DateTime', coerce => 1, lazy => 1,
                     default => sub { shift->_time }, init_arg => '__time');
has '_time'      => (is => 'ro', isa => 'Defined', init_arg => 'time',
                     lazy => 1, default => sub { shift->build_time });
has 'path'       => (is => 'ro', isa => 'Path', coerce => 1, lazy => 1,
                     default => sub { shift->_path }, init_arg => '__path');
has '_path'      => (is => 'ro', isa => 'Defined', required => 1,
                     init_arg => 'path');
has 'name'       => (is => 'ro', isa => 'Str', lazy => 1,
                     default => sub { shift->path->last });

has 'parent'     => (is => 'ro', does => 'VCI::Abstract::Committable',
                     lazy => 1, default => sub { shift->build_parent });
has 'project'    => (is => 'ro', isa => 'VCI::Abstract::Project',
                     required => 1);

# Unfortunately Moose is a little dumb about Roles sometimes, and requires
# our *abstract* classes to implement these, instead of our subclasses. So
# we can't really require them.
# requires 'build_revision', 'build_time';

sub build_first_revision {
    my $self = shift;
    my $commit = $self->history->commits->[0];
    return $self->_me_from($commit);
}

sub build_last_revision {
    my $self = shift;
    my $commit = $self->history->commits->[-1];
    return $self->_me_from($commit);
}

sub _me_from {
    my ($self, $commit) = @_;
    my @item = grep {$_->path->stringify eq $self->path->stringify
                     # This assures we don't get a Directory if we're a File.
                     && $_->isa(blessed $self)}
                    @{$commit->contents};
    warn("More than one item in the contents of commit "
         . $commit->revision . " with path " . $self->path)
        if scalar @item > 1;
    return $item[0];
}

sub build_history {
    my $self = shift;
    
    my $current_path = $self->path->stringify;
    my @commits;
    # We go backwards in time to catch renames.
    foreach my $item (reverse @{ $self->project->history->commits }) {
        my $in_contents = grep {$_->path->stringify eq $current_path}
                               @{$item->contents};
        push(@commits, $item) if $in_contents;
        if (exists $item->moved->{$current_path}) {
            $current_path = $item->moved->{$current_path};
        }
    }
    
    return VCI::VCS::Bzr::History->new(
        commits => [reverse @commits],
        project => $self->project,
    );
}

sub build_parent {
    my $self = shift;
    my $path = $self->path;
    return undef if $path->is_empty;

    my $parent_path = $self->path->parent;
    return $self->project->get_path($parent_path);
}

1;

__END__

=head1 NAME

VCI::Abstract::Committable - Anything that can be committed to a repository.

=head1 DESCRIPTION

This is a L<Moose::Role> that represents any item that can be committed
to a repository. In other words, a File I<or> a Directory.

It represents it at a specific time in its history, so it has a revision
identifier and time.

=head1 CONSTRUCTION

When you call C<new> on a Committable, if you don't specify C<revision> and
C<time>, then we assume that you're talking about the most recent version
that's in the repository, and L</revision> and L</time> will return the
revision and time of the most recent revision.

=head1 METHODS

=head2 Accessors

All accessors are read-only.

A lot of these accessors have to do with revision identifiers. Some
committables (such as directories) might not I<have> revision identifiers
of their own in certain types of version-control systems. In this case,
the revision identifiers will always be C<undef>, but they will still
have revision times. (</first_revision> and L</last_revision> might be
equal to each other, though.)

=head3 Information About The History of the Item

These are accessors that don't tell you about I<this> particular
file or directory, but actually tell you about its history in the repository.

=over

=item C<history>

A L<VCI::Abstract::History> representing the history of all commits to this
item.

Note that this L<VCI::Abstract::History> object is only guaranteed to have
information about I<this> file or directory--it may or may not contain
information about commits to other items.

=item C<first_revision>

A L<VCI::Abstract::Committable> representing the earliest revision for this
item in the current Project.

This will be the same type of Committable as the current one. (For example,
if this is a L<VCI::Abstract::File>, then C<first_revision> will also
be a L<VCI::Abstract::File>.)

=item C<last_revision>

A L<VCI::Abstract::Committable> representing the most recent revision for this
item in the current Project.

This will be the same type of Committable as the current one. (For example,
if this is a L<VCI::Abstract::File>, then C<last_revision> will also
be a L<VCI::Abstract::File>.)

=back

=head3 Information About This Point In History

This is the current revision and time of the specific item you're looking
at right now. If you're looking at an old verion of the file/directory,
it may not be the same as the information about the most recent revision.

=over

=item C<revision>

The revision identifier of the particular item that you're dealing with
right now.

=item C<time>

A timestamp (an integer number of seconds since January 1, 1970) representing
the time that this revision was committed to the repository.

=item C<path>

The file system path, from the project directory, of this file,
including its filename if it's a file.

In most version-control systems, this will never change, but there are
some modern systems that understand the idea of moving or renaming a file,
so this could be different at different points in history.

=item C<name>

The particular name of just this item, without its full path. If it's a
directory, it will just be the name of the directory (without any separators
like C<E<sol>>).

Just like L</path>, this may change over time in some version-control systems.

For the root directory of a project, this will be an empty string.

=item C<parent>

The L<VCI::Abstract::Directory> that contains this item. If this is the
root directory of the Project, then this will be C<undef>.

The most reliable way to check if this is the root directory is to see if this
accessor returns C<undef>.

=item C<project>

The L<VCI::Abstract::Project> that this committable is in.

=back
