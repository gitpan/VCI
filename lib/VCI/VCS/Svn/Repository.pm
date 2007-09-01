package VCI::VCS::Svn::Repository;
use Moose;

use SVN::Ra;

use VCI::VCS::Svn::Directory;
use VCI::VCS::Svn::Project;

extends 'VCI::Abstract::Repository';

has 'x_ra' => (is => 'ro', isa => 'SVN::Ra', lazy => 1,
               default => sub { SVN::Ra->new(url => shift->root) });

sub BUILD { shift->_root_always_ends_with_slash }

sub build_projects {
    my $self = shift;
    # XXX Should use x_ra instead, here, to re-use existing connection.
    my $ctx = $self->vci->x_client;
    # XXX Handle SVN::Error.
    my $contents = $ctx->ls($self->root, undef, 0);
    my @projects;
    foreach my $name (keys %$contents) {
        my $item = $contents->{$name};
        
        my $project = VCI::VCS::Svn::Project->new(
            name => $name, repository => $self);
        # Since we've got a dirent already for each of these, might as
        # well just use it.
        $project->{root_directory} = VCI::VCS::Svn::Directory->new(
            path => '', project => $project, x_info => $item);
        push(@projects, $project);
    }
    
    return \@projects;
}

__PACKAGE__->meta->make_immutable;

1;
