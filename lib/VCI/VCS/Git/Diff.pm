package VCI::VCS::Git::Diff;
use Moose;

use VCI::Abstract::Diff::File;

extends 'VCI::Abstract::Diff';

sub _transform_filename {
    my ($self, $name) = @_;
    $name =~ s|^[ab]/||;
    return $name;
}

1;
