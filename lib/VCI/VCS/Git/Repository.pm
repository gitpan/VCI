package VCI::VCS::Git::Repository;
use Moose;

use VCI::VCS::Git::Project;

extends 'VCI::Abstract::Repository';

sub BUILD { shift->_root_always_ends_with_slash }

sub build_projects {
    my $self = shift;
    my $root = $self->root;
    my @directories = glob "$root*/.git";
    # XXX Path Separator assumption
    @directories = map { s|/.git$||; s|^\Q$root\E||; $_ } @directories;
    return [map { VCI::VCS::Git::Project->new(name => $_, repository => $self) }
                @directories];
}

__PACKAGE__->meta->make_immutable;

1;
