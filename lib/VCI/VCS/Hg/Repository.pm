package VCI::VCS::Hg::Repository;
use Moose;
use MooseX::Method;

use VCI::VCS::Hg::Project;

extends 'VCI::Abstract::Repository';

sub BUILD { shift->_root_always_ends_with_slash }

# XXX Probably need to make Repository::Web and Repository::Local.

# Mostly uses hgweb, right now.
method 'x_get' => positional (
     { isa => 'Path', coerce => 1, required => 1 },
) => sub {
    my ($self, $path) = @_;
    my $full_path = $self->root . $path->stringify;
    if ($self->vci->debug) {
        print STDERR "Getting $full_path\n";
    }
    my $result = $self->vci->x_ua->get($full_path);
    if (!$result->is_success) {
        confess("Error getting $full_path: " . $result->status_line);
    }
    return $result->content;
};

sub build_projects {
    my $self = shift;
    my $list = $self->x_get('?style=raw');
    my @lines = split("\n", $list);
    my @projects;
    foreach my $dir (@lines) {
        $dir =~ s|^/||;
        $dir =~ s|/$||;
        push(@projects, VCI::VCS::Hg::Project->new(name => $dir,
                                                   repository => $self));
    }
    return \@projects;
}

__PACKAGE__->meta->make_immutable;

1;
