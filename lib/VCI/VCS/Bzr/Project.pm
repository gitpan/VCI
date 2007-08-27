package VCI::VCS::Bzr::Project;
use Moose;

use Path::Abstract;
use VCI::VCS::Bzr::Directory;
use VCI::VCS::Bzr::File;
use VCI::VCS::Bzr::History;

extends 'VCI::Abstract::Project';

sub BUILD {
    my $self = shift;
    $self->_name_never_ends_with_slash();
}

sub build_history {
    my $self = shift;
    my $full_path = $self->repository->root . $self->name;
    my $xml_string = $self->repository->vci->x_do(
        args => [qw(log -v --xml), $full_path]);
    return VCI::VCS::Bzr::History->x_from_xml($xml_string, $self);
}

# XXX Perhaps we should only get the contents when they're actually
#     requested. But who would even build a root_directory unless
#     they wanted its contents? Well...maybe they want contents_history.
sub build_root_directory {
    my $self = shift;
    my $root = $self->repository->root . $self->name;
    my $dir_names = $self->repository->vci->x_do(
        args => ['ls', '--kind=directory', $root]);
    my $file_names = $self->repository->vci->x_do(
        args => ['ls', '--kind=file', $root ]);

    # XXX We don't support symlinks yet.

    my $root_directory =
        VCI::VCS::Bzr::Directory->new(path => '', project => $self);
    
    return $self->_directory_from_list($root_directory,
        [split("\n", $dir_names)], [split("\n", $file_names)], $root);
}

__PACKAGE__->meta->make_immutable;

1;
