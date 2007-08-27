package VCI::VCS::Svn::File;
use Moose;

with 'VCI::VCS::Svn::Committable';
extends 'VCI::Abstract::File';

# XXX Must implement this.
sub build_is_executable { undef }

__PACKAGE__->meta->make_immutable;

1;
