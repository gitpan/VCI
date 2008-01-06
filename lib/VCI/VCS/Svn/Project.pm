package VCI::VCS::Svn::Project;
use Moose;
use MooseX::Method;

use Path::Abstract;
use SVN::Core;

use VCI::VCS::Svn::Commit;
use VCI::VCS::Svn::Directory;
use VCI::VCS::Svn::History;

extends 'VCI::Abstract::Project';

sub BUILD {
    my $self = shift;
    $self->_name_never_ends_with_slash();
    $self->_name_never_starts_with_slash();
}

method 'get_commit' => named (VCI::Abstract::Project::get_commit_prototype()) =>
sub {
    my $self = shift;
    my $params = shift;

    # MooseX::Method always has a hash key for each parameter, even if they
    # weren't passed by the caller.
    delete $params->{$_} foreach (grep { !defined $params->{$_} } keys %$params);
    
    # We only use our custom implementation if the History object
    # doesn't already exist, and if we were just asked for a revision id.
    if (!defined $self->{history} && defined $params->{revision}
        && keys(%$params) == 1)
    {
        my $commits = $self->_x_get_commits(
            start => $params->{revision}, end => $params->{revision},
            limit => 1);
        return $commits->[0];
    }
    
    unshift(@_, $params);
    return $self->SUPER::get_commit(@_);
};

# We need a dirent for the root directory, so we have to override the
# default build_root_directory.
sub _build_root_directory {
    my $self = shift;
    # XXX Probably should use x_ra.
    my $ctx = $self->repository->vci->x_client;
    my $info;
    # Getting the root_directory of the root_project only works if there's
    # no slash on the end of the URL.
    my $name = $self->name eq '' ? '' : ('/' . $self->name);
    $ctx->info($self->repository->x_root_noslash . $name, undef,
               'HEAD', sub { $info = $_[1] }, 0);
    return VCI::VCS::Svn::Directory->new(
        path => '', project => $self, x_info => $info);
}

sub _build_history {
    my $self = shift;
    my $commits = $self->_x_get_commits();
    return VCI::VCS::Svn::History->new(commits => $commits, project => $self);
}

method '_x_get_commits' => named (
    start => { isa => 'Int', default => $SVN::Core::INVALID_REVNUM },
    end   => { isa => 'Int' },
    limit => { isa => 'Int', default => 0 },
    path  => { isa => 'Str' },
) => sub {
    my ($self, $params) = @_;
    my $ra = $self->repository->x_ra;
    $params->{path} ||= $self->name;
    $params->{end}  ||= $ra->get_latest_revnum;

    my @commits;
    $ra->get_log([$params->{path}], $params->{start}, $params->{end},
                                   # discover_changed_paths, strict_node_history
                 $params->{limit}, 1, 0,
                 sub { push(@commits, VCI::VCS::Svn::Commit->x_from_log($self, @_)) });
    return \@commits;
};

__PACKAGE__->meta->make_immutable;

1;
