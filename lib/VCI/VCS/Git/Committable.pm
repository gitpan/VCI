package VCI::VCS::Git::Committable;
use Moose::Role;

sub build_revision {
    my $self = shift;
    my $head_rev = $self->project->x_do('rev-list', ['--max-count=1', 'HEAD'], 1);
    return $head_rev;
}

sub build_time {
    my $self = shift;
    my $time = $self->project->x_do('log', ['-1', '--pretty=format:%cD', 'HEAD'], 1);
    $time =~ s/^\w{3}, //;
    return $time;
}

1;
