package VCI::VCS::Git::Committable;
use Moose::Role;

sub _build_revision {
    my $self = shift;
    my $head_rev = $self->project->x_do('rev-list',
        ['--all', '--max-count=1', '--', $self->path->stringify], 1);
    chomp($head_rev);
    return $head_rev;
}

sub _build_time {
    my $self = shift;
    my $time = $self->project->x_do('log', ['-1', '--pretty=format:%cD', '--',
                                            $self->path->stringify], 1);
    chomp($time);
    $time =~ s/^\w{3}, //;
    return $time;
}

1;
