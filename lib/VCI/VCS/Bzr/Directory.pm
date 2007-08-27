package VCI::VCS::Bzr::Directory;
use Moose;

with 'VCI::VCS::Bzr::Committable';
extends 'VCI::Abstract::Directory';

sub BUILD {
    my $self = shift;
    if ((defined $self->{revision} || defined $self->{time})
        && defined $self->{contents})
    {
        confess("You cannot specify 'revision' or 'time' without also"
                . " specifying 'contents', for a Bzr Directory");
    }
}

sub build_contents {
    my $self = shift;
    # In our current implementation, this has everything we need.
    return $self->project->get_directory($self->path)->contents;
}

__PACKAGE__->meta->make_immutable;

1;
