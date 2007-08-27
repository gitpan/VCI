package VCI::VCS::Git::Project;
use Moose;

use VCI::VCS::Git::Commit;
use VCI::VCS::Git::Directory;
use VCI::VCS::Git::History;

use Git ();

extends 'VCI::Abstract::Project';

has 'x_git' => (is => 'ro', isa => 'Git', lazy => 1,
                default => sub { shift->build_x_git });

sub build_x_git {
    my $self = shift;
    my $repo = Git->repository($self->repository->root . $self->name);
    if ($self->repository->vci->debug) {
        print STDERR "Connected to Git, Version: " . $repo->version . "\n";
    }
    return $repo;
}

sub x_do {
    my ($self, $command, $args, $as_string) = @_;
    $args ||= [];
    my $git = $self->x_git;
    if ($self->repository->vci->debug) {
        print STDERR "Calling [" . $git->exec_path . "/git $command "
            . join(' ', @$args) . "] on [" . $git->repo_path . "]";
    }
    if ($as_string) {
        return scalar $git->command($command, @$args);
    }
    return [$git->command($command, @$args)];
}

# XXX This should probably be optimized to not build a File object for
#     every file in the whole repo--it's a bit slow on the kernel sources
#     (over 20,000 files).
sub build_root_directory {
    my $self = shift;
    my $files = $self->x_do('ls-files');
    
    # Get the directory names from the output
    my %dirs;
    foreach my $line (@$files) {
        # XXX This assumes the path separator is always /.
        if ($line =~ m|^(.+)/[^/]+$|) {
            $dirs{$1} = 1;
        }
    }
    
    # Make sure that every dir has a parent in the list.
    my @new_dirs;
    my @check_dirs = keys %dirs;
    my $found_parent = 1;
    while ($found_parent) {
        $found_parent = 0;
        foreach my $dir (@check_dirs) {
            # If this directory has a parent... (XXX path separator assumption)
            if ($dir =~ m|^(.+)/[^/]+$|) {
                my $parent_dir = $1;
                # And that parent isn't already in the list...
                if (!$dirs{$parent_dir}) {
                    push(@new_dirs, $parent_dir);
                    $found_parent = 1;
                }
            }
        }

        $dirs{$_} = 1 foreach @new_dirs;
        @check_dirs = @new_dirs;
    }
    
    my $root_directory =
        VCI::VCS::Git::Directory->new(path => '', project => $self);
    
    return $self->_directory_from_list($root_directory, [keys %dirs],
        $files);
}

# Because git is so fast with individual operations, we don't pull in
# every log detail for the whole history with this, like we do for other
# drivers. We just get the list of revision IDs and then the commits can
# populate themselves.
sub build_history {
    my $self = shift;
    my $lines = $self->x_do('log', ['--pretty=format:%H%n%cD%n%cn <%ce>%n',
                                    '--reverse', '-m'], 1);
    my @messages = split("\n\n", $lines);
    @messages = @messages[1..1000]; # XXX
    my @commits;
    foreach my $message (@messages) {
        my ($id, $time, $committer) = split("\n", $message);
        # Times start with "Wed" or "Thu", etc., which Date::Parse can't handle.
        $time =~ s/^\w{3}, //;
        push(@commits, VCI::VCS::Git::Commit->new(revision => $id,
            time => $time, committer => $committer, project => $self));
    }
    return VCI::VCS::Git::History->new(commits => \@commits, project => $self);
}

__PACKAGE__->meta->make_immutable;

1;
