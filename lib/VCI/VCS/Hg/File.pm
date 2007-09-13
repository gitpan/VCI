package VCI::VCS::Hg::File;
use Moose;

extends 'VCI::Abstract::File';
with 'VCI::VCS::Hg::Committable';

# XXX From a Commit, we don't currently track if a file is executable or not.
sub build_is_executable { undef }

sub build_content {
    my $self = shift;
    return $self->project->x_get(['raw-file', $self->revision, $self->path])
}

__PACKAGE__->meta->make_immutable;

1;
