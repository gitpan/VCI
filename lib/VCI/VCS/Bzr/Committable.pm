package VCI::VCS::Bzr::Committable;
use Moose::Role;

sub BUILD {
    my $self = shift;
    # This condition is because bzr can't reliably get a revision number
    # if provided with just a time.
    if (defined $self->{time} && !defined $self->{revision}) {
        confess("You cannot build a Bzr Committable that has its time"
                . " defined but not its revision.");
    }
}

sub build_time {
    my $self = shift;
    my $commit = $self->_x_this_commit;
    # Since we've got it now, set the revision if it's not set.
    if (!defined $self->{revision}) {
        $self->{revision} = $commit->revision;
    }
    return $commit->time;
}

sub build_revision {
    my $self = shift;
    my $commit = $self->_x_this_commit;
    # Since we've got it now, set the time if it's not set.
    if (!defined $self->{time}) {
        $self->{time} = $commit->time;
    }
    return $commit->revision;
}

sub _x_this_commit {
    my $self = shift;

    if (defined $self->{revision}) {
        # XXX To optimize, could check ->history before going to bzr.
        #     However, I'm not aware of any situation where we already have
        #     a history but don't have a time/revision.

        require VCI::VCS::Bzr::History; # Have to "require" to avoid dep loops.
        my $vci = $self->project->repository->vci;
        my $obj_path = Path::Abstract->new($self->project->name, $self->path);
        my $full_path = $self->project->repository->root . $obj_path->stringify;
        my $rev = $self->revision;
        my $log = $vci->x_do(args => ['log', '--xml', "--revision=$rev",
                                      $full_path]);
        my $hist = VCI::VCS::Bzr::History->x_from_xml($log, $self->project);
        return $hist->commits->[0];
    }

    return $self->last_revision;
}

1;
