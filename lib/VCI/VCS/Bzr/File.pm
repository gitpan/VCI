package VCI::VCS::Bzr::File;
use Moose;

with 'VCI::VCS::Bzr::Committable';
extends 'VCI::Abstract::File';

__PACKAGE__->meta->make_immutable;

1;
