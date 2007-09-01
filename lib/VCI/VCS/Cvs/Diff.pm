package VCI::VCS::Cvs::Diff;
use Moose;

extends 'VCI::Abstract::Diff';

sub _transform_filename {
    my ($self, $name) = @_;
    my $project = $self->project->name;
    $name =~ s|^\Q$project\E/||;
    return $name;
}

1;
