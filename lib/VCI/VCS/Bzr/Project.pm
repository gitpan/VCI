package VCI::VCS::Bzr::Project;
use Moose;

use Path::Abstract::Underload;
use VCI::VCS::Bzr::Directory;
use VCI::VCS::Bzr::File;
use VCI::VCS::Bzr::History;

extends 'VCI::Abstract::Project';

sub BUILD {
    my $self = shift;
    $self->_name_never_ends_with_slash();
    $self->_name_never_starts_with_slash();
}

sub _build_history {
    my $self = shift;
    my $full_path = $self->repository->root . $self->name;
    my $xml_string = $self->repository->vci->x_do(
        args => [qw(log --xml), $full_path]);
    return VCI::VCS::Bzr::History->x_from_xml($xml_string, $self);
}

__PACKAGE__->meta->make_immutable;

1;
