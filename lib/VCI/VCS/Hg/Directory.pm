package VCI::VCS::Hg::Directory;
use Moose;

use VCI::VCS::Hg::File;

extends 'VCI::Abstract::Directory';
with 'VCI::VCS::Hg::Committable';

sub build_contents {
    my $self = shift;
    my $ls_out = $self->project->x_get([$self->path, 'raw-file/', $self->revision]);
    my @lines = split("\n", $ls_out);
    my @dir_lines = grep(/^d/, @lines);
    my @file_lines = grep(/^-/, @lines);
    
    my @contents;
    foreach my $dir_line (@dir_lines) {
        $dir_line =~ /^\S+ (.*)$/;
        push(@contents, VCI::VCS::Hg::Directory->new(path => [$self->path, $1],
                                                     project => $self->project,
                                                     revision => $self->revision));
    }
    foreach my $file_line (@file_lines) {
        $file_line =~ /^(\S+) \d+ (.*)$/;
        my ($properties, $name) = ($1, $2);
        my $executable = 0;
        $executable = 1 if $properties =~ /x/;
        push(@contents, VCI::VCS::Hg::File->new(path => [$self->path, $name],
                                                is_executable => $executable,
                                                project => $self->project,
                                                # XXX This isn't really right.
                                                revision => $self->revision));
    }
    return \@contents;
}

__PACKAGE__->meta->make_immutable;

1;
