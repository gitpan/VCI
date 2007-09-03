package VCI::VCS::Cvs::Repository;
use Moose;
use MooseX::Method;

use Cwd qw(abs_path);

use VCI::VCS::Cvs::Project;

extends 'VCI::Abstract::Repository';

has 'x_is_local' => (is => 'ro', isa => 'Bool', default => sub { 0 });
has 'x_dir_part' => (is => 'ro', isa => 'Bool');

sub BUILD {
    my $self = shift;
    
    # Make relative local roots into absolute roots.
    my $root = $self->root;
    # XXX This test will break on Windows (C:, D:, etc.)
    if ($root =~ /^:local:/ || $root !~ /:/) {
        $root =~ /^(:local:)?(.*)$/;
        my $dir = abs_path($2);
        $self->{root} = ":local:$dir";
        $self->{x_is_local} = 1;
        # We don't yet need this set for other repos than :local: repos.
        $self->{x_dir_part} = $dir;
    }
    
    $self->_root_never_ends_with_slash;
}

sub build_projects {
    my $self = shift;
    my $root_project = $self->get_project(name => '');
    my $contents = $root_project->root_directory->contents;
    my @directories = grep { $_->isa('VCI::Abstract::Directory')
                             && $_->path->stringify ne 'CVSROOT' } @$contents;
    my @projects = map { VCI::VCS::Cvs::Project->new(
                            name => $_->path->stringify, repository => $self) }
                       @directories;
    return \@projects;
}

# XXX get_project Doesn't support modules yet.
# For get_project module support, all paths will be from the root of the
# repository. But for directory support, they will be from the root
# of the directory. Can do "cvs co -c" to get modules.

1;
