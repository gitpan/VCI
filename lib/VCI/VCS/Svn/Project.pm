package VCI::VCS::Svn::Project;
use Moose;

use Path::Abstract;
use SVN::Core;

use VCI::VCS::Svn::Commit;
use VCI::VCS::Svn::Directory;
use VCI::VCS::Svn::History;

extends 'VCI::Abstract::Project';

sub BUILD {
    my $self = shift;
    $self->_name_never_ends_with_slash();
}

# We need a dirent for the root directory, so we have to override the
# default build_root_directory.
sub build_root_directory {
    my $self = shift;
    # XXX Probably should use x_ra.
    my $ctx = $self->repository->vci->x_client;
    my $info;
    # XXX Need to check return for errors.
    $ctx->info($self->repository->root . $self->name, undef,
               'HEAD', sub { $info = $_[1] }, 0);
    return VCI::VCS::Svn::Directory->new(
        path => '', project => $self, x_info => $info);
}

sub build_history {
    my $self = shift;
    my $ra = $self->repository->x_ra;
    my @commits;
    $ra->get_log([$self->name],
                 $SVN::Core::INVALID_REVNUM, $ra->get_latest_revnum,
                 # limit, discover_changed_paths, strict_node_history
                 3000, 1, 0,
                 sub { push(@commits, VCI::VCS::Svn::Commit->x_from_log($self, @_)) });
    return VCI::VCS::Svn::History->new(commits => \@commits, project => $self);
}

__PACKAGE__->meta->make_immutable;

1;
