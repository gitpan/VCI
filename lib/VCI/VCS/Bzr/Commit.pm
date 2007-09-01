package VCI::VCS::Bzr::Commit;
use Moose;
extends 'VCI::Abstract::Commit';

use VCI::Abstract::Diff;

sub build_as_diff {
    my $self = shift;
    my $rev = $self->revision;
    my $previous_rev = $rev - 1;
    my $diff = $self->project->repository->vci->x_do(
        args => ['diff', "-r$previous_rev..$rev"],
        errors_ignore => [256]);
    return VCI::Abstract::Diff->new(raw => $diff, project => $self->project);
}

__PACKAGE__->meta->make_immutable;

1;
