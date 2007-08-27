package VCI::VCS::Git::Directory;
use Moose;

extends 'VCI::Abstract::Directory';
with 'VCI::VCS::Git::Committable';

# This works because the default get_directory uses root_directory
# and so we've already built all of root_directory.
#
# XXX However, this is only proper for tip revisions of directories.
sub build_contents {
    my $self = shift;
    # In our current implementation, this has everything we need.
    return $self->project->get_directory($self->path)->contents;
}

__PACKAGE__->meta->make_immutable;

1;
