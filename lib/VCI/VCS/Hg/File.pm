package VCI::VCS::Hg::File;
use Moose;

extends 'VCI::Abstract::File';
with 'VCI::VCS::Hg::Committable';

__PACKAGE__->meta->make_immutable;

# XXX From a Commit, we don't currently track if a file is executable or not.
sub build_is_executable { undef }

1;
