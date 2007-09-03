package VCI::VCS::Bzr::Directory;
use Moose;

with 'VCI::VCS::Bzr::Committable';
extends 'VCI::Abstract::Directory';

# XXX Currently always returns HEAD contents.
sub build_contents {
    my $self = shift;
    my $root = $self->project->repository->root . $self->project->name . '/'
               . $self->path->stringify;
    # XXX We don't support symlinks yet.
    my $dir_names = $self->project->repository->vci->x_do(
        args => ['ls', '--kind=directory', $root]);
    my $file_names = $self->project->repository->vci->x_do(
        args => ['ls', '--kind=file', $root ]);
    $self->_set_contents_from_list(
        [split("\n", $dir_names)], [split("\n", $file_names)], $root);
    return $self->{contents};
}

__PACKAGE__->meta->make_immutable;

1;
