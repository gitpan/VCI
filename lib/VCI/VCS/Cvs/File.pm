package VCI::VCS::Cvs::File;
use Moose;

extends 'VCI::Abstract::File';

# XXX If we have a History, these two should probably just use latest_revision.

sub build_revision {
    my $self = shift;
    my $output = $self->project->repository->vci->x_do(
        args    => ['-n', 'status', $self->name],
        fromdir => $self->parent->x_cvs_dir);
    $output =~ /^\s+Repository revision:\s([\d\.]+)/ms;
    return $1;
}

sub build_time {
    my $self = shift;
    my $output = $self->project->repository->vci->x_do(
        args => ['-n', 'log', '-N', '-rHEAD', $self->name],
        fromdir => $self->parent->x_cvs_dir);
    $output =~ /^date: (\S+ \S+);/ms;
    return "$1 UTC";
}

__PACKAGE__->meta->make_immutable;

1;
