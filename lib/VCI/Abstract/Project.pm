package VCI::Abstract::Project;
use Moose;
use MooseX::Method;

use VCI::Util;

has 'name'       => (is => 'ro', isa => 'Str', required => 1);
has 'repository' => (is => 'ro', isa => 'VCI::Abstract::Repository',
                     required => 1);
has 'history'    => (is => 'ro', isa => 'VCI::Abstract::History', lazy => 1,
                     default => sub { shift->build_history });
has 'root_directory' => (is => 'ro', isa => 'VCI::Abstract::Directory',
                         lazy => 1,
                         default => sub { shift->build_root_directory });

sub get_commit {
    my ($self, $revision) = @_;
    my @items = grep { $_->revision eq $revision } @{$self->history->commits};
    warn "More that one commit found with revision $revision"
        if scalar @items > 1;
    return $items[0];
}

method 'get_history_by_time' => named (
    start => { isa => 'DateTime', coerce => 1 },
    end   => { isa => 'DateTime', coerce => 1 },
    at    => { isa => 'DateTime', coerce => 1 },
) => sub {
    my ($self, $params) = @_;
    my $start = $params->{start};
    my $end   = $params->{end};
    my $at    = $params->{at};
    
    if ( !(defined $start || defined $end || defined $at) ) {
        confess("Either 'start', 'end', or 'at' must be passed to"
                . " get_commits_by_time");
    }
    if ( defined $at && (defined $start || defined $end) ) {
        confess("You cannot specify 'start' and 'end' with 'at'");
    }
    
    my @commits;
    if (defined $at) {
        @commits = grep { $_->time == $at } @{$self->history->commits};
    }
    else {
        @commits = grep { (!$start || $_->time >= $start)
                           && (!$end || $_->time <= $end) }
                        @{$self->history->commits};
    }

    my $vci = $self->repository->vci;
    return $vci->history_class->new(commits => \@commits, project => $self);
};

# XXX All these methods will need "revision" and "as_of".

method 'get_directory' => named (
    path => { isa => 'Path', coerce => 1, required => 1 },
) => sub {
    my ($self, $params) = @_;
    my $path = $params->{path};
    
    my $root = $self->root_directory;
    return $root if $path->is_empty;
    
    my @dirs = $path->list;
    my $current_dir = $root;
    while (my $dir_name = shift @dirs) {
        my $contents = $current_dir->contents;
        my @matches = grep { $_->isa('VCI::Abstract::Directory')
                             && $_->name eq $dir_name } @$contents;
        
        return undef if !@matches;
        warn("More than one directory in " . $current_dir->path
             . " is called '$dir_name'") if scalar @matches > 1;
        $current_dir = $matches[0];
    }

    return $current_dir;
};

method 'get_file' => named (
    path => { isa => 'Path', coerce => 1, required => 1 },
) => sub {
    my ($self, $params) = @_;
    my $path = $params->{path};
    
    confess("Empty path name passed to get_file.") if $path->is_empty;

    my $dir = $self->get_directory(path => $path->parent);
    confess("No directory named " . $path->parent) if !$dir;
    
    my $filename = $path->last;
    
    my @matches = grep { $_->isa('VCI::Abstract::File')
                         && $_->name eq $filename } @{$dir->contents};
    
    return undef if !@matches;
    warn("More than one file in " . $dir->path . " is called '$filename'.")
        if scalar @matches > 1;
    return $matches[0];
};

method 'get_path' => named (
    path => { isa => 'Path', coerce => 1, required => 1 },
) => sub {
    my ($self, $params) = @_;
    my $path = $params->{path};

    return $self->root_directory if $path->is_empty;

    my $dir = $self->get_directory(path => $path->parent);
    confess("No directory named " . $path->parent) if !$dir;

    my $name = $path->last;
    my @matches = grep { $_->name eq $name } @{$dir->contents};
    return undef if !@matches;
    warn("More than one item in " . $dir->path . " is called '$name'.")
        if scalar @matches > 1;
    return $matches[0];
};

sub build_root_directory {
    my $self = shift;
    return $self->repository->vci->directory_class->new(path => '',
                                                        project => $self);
}

####################
# Subclass Helpers #
####################

# For use in BUILD
sub _name_never_ends_with_slash   { $_[0]->{name} =~ s|/+\s*$|| }
sub _name_never_starts_with_slash { $_[0]->{name} =~ s|^\s*/+|| }

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

VCI::Abstract::Project - A particular project in the Repository

=head1 SYNOPSIS

 my $project = $repository->get_project(name => 'Foo');

 # Getting information about individual files/directories.

 my $file = $project->get_file(path => 'path/to/file.c');
 my $directory = $project->get_file(path => 'path/to/directory/');

 my $file = $project->get_path(path => 'path/to/file.c');
 my $directory = $project->get_path(path => 'path/to/directory/');

 # Commits

 my $commit = $project->get_commit('123');
 my $commits = $project->get_history_by_time(start => 'January 1, 1970',
                                             end   => '2007-01-01');
 my ($commit) =
     @{ $project->get_history_by_time(at => 'July 7, 2007 12:01:22 UTC') };

 # Other information

 my $root_directory = $project->root_directory;
 my $history = $project->history;
 my $name = $project->name;

 $repository == $project->repository # True

=head1 DESCRIPTION

This represents a Project, something that could be checked out of a
L<Repository|VCI::Abstract::Repository>.

For example, the Mozilla CVS Repository contains Firefox and Thunderbird
as Projects.

=head1 METHODS

=head2 Accessors

All of these accessors are read-only.

=over

=item C<name>

The name of the Project, as a string. This is something that you could
pass to L<VCI::Abstract::Repository/get_project> to get this Project.

=item C<repository>

The L<VCI::Abstract::Repository> that this Project is in.

=item C<history>

The L<VCI::Abstract::History> of this whole Project.

=item C<root_directory>

The root L<VCI::Abstract::Directory>, containing this project's
L<files|VCI::Abstract::File> and L<directories|VCI::Abstract::Directory>.

=back

=head2 Files and Directories

Methods to get information about specific files and directories.

Note that paths are case-sensitive in the default implementation of
VCI, but particular drivers may be case-insensitive (for example,
for version-control systems that are on Windows servers). However,
it is best not to rely on case-insensitivity, and always specify your
file names assuming that VCI will be case-sensitive.

=over

=item C<get_path>

=over

=item B<Description>

When you have a path but you don't know if it's a file or a directory,
use this function to get it as an object.

If you know that you want a file, or know that you want a directory,
it is recommended that you use L</get_file> or L</get_directory>
instead.

=item B<Parameters>

Takes one named parameter:

=over

=item C<path>

A L<Path|VCI::Util/Path> to the file or directory that you want, relative to
the base of the project.

Absolute paths will be interpreted as relative to the base of the project.

If you pass an empty string or C<"/">, you will get the root directory
of the Project.

=back

=item B<Returns>

An object that implements L<VCI::Abstract::Committable>, either a file
or a directory.

If there is no object with that path, will return C<undef>. However,
if you specify a parent directory that doesn't exist, we will C<die>.

So, for example, if you ask for F</path/to/file.c> and F</path/to/> is a valid
directory but doesn't contain F<file.c>, we will return C<undef>. But if
F</path/to/> is not a valid directory, we will C<die>. Also, if F</path> is not
a valid directory, we will C<die>.

=back

=item C<get_directory>

=over

=item B<Description>

Gets a L<directory|VCI::Abstract::Directory> from the repository.

=item B<Parameters>

Takes one named parameter:

=over

=item C<path>

A L<Path|VCI::Util/Path> to the directory that you want, relative to
the base of the project.

Absolute paths will be interpreted as relative to the base of the project.

If you pass an empty string or C<"/">, you will get the root directory
of the Project.

=back

=item B<Returns>

A L<VCI::Abstract::Directory>, or C<undef> if there is no I<directory>
with that name. (Even if there's a file with that name, if it's not a
directory, we will still return C<undef>.)

Also, if any of the parent directories don't exist, we return C<undef>.

=back

=item C<get_file>

=over

=item B<Description>

Gets a L<file|VCI::Abstract::File> from the repository.

=item B<Parameters>

Takes one named parameter:

=over

=item C<path>

A L<Path|VCI::Util/Path> to the file that you want, relative to
the base of the project.

Absolute paths will be interpreted as relative to the base of the project.

This method will throw an error if you pass in an empty string or just C<"/">.

=back

=item B<Returns>

A L<VCI::Abstract::Directory>, or C<undef> if there is no I<file>
with that name. (Even if there's I<something> with that name, if it's not a
file, we will still return C<undef>.)

If the parent directory doesn't exist, or any of the parent directories
don't exist, this will throw an error (identically to how L</get_path> works).

=back

=back

=head2 Commits to the Project

=over

=item C<get_commit>

=over

=item B<Description>

Gets a particular L<commit|VCI::Abstract::Commit> from the Project by
its unique identifier.

=item B<Parameters>

Takes a single parameter: C<$revision>, the unique identifier of the commit
that you want, as a string.

See L<VCI::Abstract::Commit/revision> for a discussion of exactly what a
revision identifier is.

=item B<Returns>

The L<VCI::Abstract::Commit> that you asked for, or C<undef> if there is
no commit with that ID in this Project.

=back

=item C<get_history_by_time>

=over

=item B<Description>

Get a section of the Project's history based on times.

=item B<Parameters>

Takes the following named parameters. At least I<one> of them must be
specified.

You can either search a range of times using C<start> and C<end>, or
you can ask for a specific time using C<at>.

=over

=item C<start>

A L<datetime|VCI::Util/DateTime>.

The earliest revision you want returned. (Search is "inclusive", so if
the time of the commit matches C<start> exactly, it I<will> be returned.)

If you specify C<start> without C<end>, we search from C<start> to the
most recent commit.

=item C<end>

A L<datetime|VCI::Util/DateTime>.

The latest revision you want returned. (Search is "inclusive", so if
the time of the commit matches C<end> exactly, it I<will> be returned.)

If you specify C<end> without C<start>, we search from the beginning of time
to C<end>.

=item C<at>

A L<datetime|VCI::Util/DateTime>.

Specifies that you want the commits that happened at an exact moment in
time.

=back

=item B<Returns>

A L<VCI::Abstract::History> for the project representing the times that
you asked for. If there were no commits matching your criteria, the
History will be empty.

=back

=back

=head1 CLASS METHODS

=head2 Constructors

Usually you won't construct an instance of this class directly, but
instead, use L<VCI::Abstract::Repository/get_project> or
L<VCI::Abstract::Repository/projects>.

=over

=item C<new>

Takes all L</Accessors> of this class as named parameters. The following
fields are B<required>: L</name> and L</repository>.

=back
