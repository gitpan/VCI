package VCI::VCS::Svn::Directory;
use Moose;

use VCI::VCS::Svn::File;

use Path::Abstract;
use SVN::Core;

with 'VCI::VCS::Svn::Committable';
extends 'VCI::Abstract::Directory';

sub build_contents {
    my $self = shift;
    my $project = $self->project;
    # XXX Should use x_ra instead, here, to re-use existing connection.
    my $ctx = $project->repository->vci->x_client;
    my $dir_path  = Path::Abstract->new($project->name, $self->path);
    my $full_path = $project->repository->root . $dir_path->stringify;
    # XXX Handle SVN::Error.
    my $svn_contents = $ctx->ls($full_path, $self->revision, 0);
    my @contents;
    foreach my $name (keys %$svn_contents) {
        my $item = $svn_contents->{$name};
        my $path = Path::Abstract->new($self->path, $name);
        if ($item->kind == $SVN::Node::dir) {
            my $dir = VCI::VCS::Svn::Directory->new(
                path => $path, project => $project, parent => $self,
                x_info => $item);
            push(@contents, $dir);
        }
        elsif ($item->kind == $SVN::Node::file) {
            my $file = VCI::VCS::Svn::File->new(
                path => $path, project => $project, parent => $self,
                x_info => $item);
            push(@contents, $file);
        }
    }
    
    return \@contents;
}

__PACKAGE__->meta->make_immutable;

1;
