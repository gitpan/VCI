package VCI::VCS::Svn::Repository;
use Moose;

use Cwd qw (abs_path);
use SVN::Ra;

use VCI::VCS::Svn::Directory;
use VCI::VCS::Svn::Project;

extends 'VCI::Abstract::Repository';

has 'x_ra' => (is => 'ro', isa => 'SVN::Ra', lazy => 1,
               default => sub { SVN::Ra->new(url => shift->x_root_noslash) });

# The SVN libraries throw an error in certain cases if the root ends with
# a slash.
has 'x_root_noslash' => (is => 'ro', isa => 'Str', lazy => 1,
    default => sub { my $root = shift->root; $root =~ s|/+\s*$||; $root });

sub BUILD {
    my $self = shift;
    # Make relative local roots into absolute roots.
    my $root = $self->root;
    if ($root =~ m|^file://|) {
        $root =~ m|^file://(localhost/)?(.*)$|;
        my $dir = abs_path($2);
        $self->{root} = "file://$dir";
    }
    $self->_root_always_ends_with_slash;
}

sub build_projects {
    my $self = shift;
    # XXX Should use x_ra instead, here, to re-use existing connection.
    my $ctx = $self->vci->x_client;
    # XXX Handle SVN::Error.
    my $contents = $ctx->ls($self->x_root_noslash, undef, 0);
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

sub build_root_project { $_[0]->_root_project; }

__PACKAGE__->meta->make_immutable;

1;
