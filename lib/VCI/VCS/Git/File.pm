package VCI::VCS::Git::File;
use Moose;

extends 'VCI::Abstract::File';
with 'VCI::VCS::Git::Committable';

__PACKAGE__->meta->make_immutable;

1;
