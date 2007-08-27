package VCI::VCS::Hg::Project;
use Moose;
use MooseX::Method;

use XML::Simple;

use VCI::VCS::Hg::History;

extends 'VCI::Abstract::Project';

sub BUILD {
    my $self = shift;
    $self->_name_never_ends_with_slash();
}

sub x_get {
    my ($self, $path) = @_;
    my @path = ref $path eq 'ARRAY' ? @$path : $path;
    return $self->repository->x_get([$self->name, @path]);
};

# Currently, we just get the first items listed in the changelog, and
# just assume that changesets exist from this one back to #1. The
# changesets themselves can easily modify themselves.
sub build_history {
    my $self = shift;
    return VCI::VCS::Hg::History->x_from_rss('', $self);
}

__PACKAGE__->meta->make_immutable;

1;
