package VCI::VCS::Bzr::Committable;
use Moose;

use VCI::VCS::Bzr::History;

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
    if (!defined $self->{_time}) {
        $self->{time} = $commit->time;
    }
    return $commit->revision;
}

sub build_history {
    my $self = shift;
    my $full_path = $self->project->repository->root . $self->project->name
                    . '/' . $self->path->stringify;
    my $xml_string = $self->project->repository->vci->x_do(
        args => [qw(log --xml), $full_path]);
    return VCI::VCS::Bzr::History->x_from_xml($xml_string, $self->project);    
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
