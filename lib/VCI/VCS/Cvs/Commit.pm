package VCI::VCS::Cvs::Commit;
use Moose;

extends 'VCI::Abstract::Commit';

use constant REMOVE_HEADER => '
^---------------------\n
PatchSet\s\d+\s?\n
Date:\s\S+\s\S+\n
Author:\s\S+\n
Branch:\s\S+\n
Tag:\s[^\n]+\s?\n
Log:\n
.*\n
\n
Members:\s?\n';

sub _build_as_diff {
    my $self = shift;
    my $diff = $self->project->x_cvsps_do(['-g', '-s', $self->revision]);
    my $header_re = REMOVE_HEADER;
    # Pull off the header
    $diff =~ s/$header_re//sox;
    # Pull off lines now until we get to "Index:"
    $diff =~ s/^\s+.*?(^Index)/$1/ms;
    return $self->diff_class->new(raw => $diff, project => $self->project);
}

__PACKAGE__->meta->make_immutable;

1;
