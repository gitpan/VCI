package VCI::VCS::Bzr::Commit;
use Moose;
extends 'VCI::Abstract::Commit';
use VCI::Abstract::Diff;

has 'x_changes' => (is => 'ro', isa => 'HashRef', lazy => 1,
                    default => sub { shift->build_x_changes });

sub build_as_diff {
    my $self = shift;
    my $rev = $self->revision;
    my $previous_rev = $rev - 1;
    my $diff = $self->project->repository->vci->x_do(
        args => ['diff', "-r$previous_rev..$rev"],
        errors_ignore => [256]);
    return VCI::Abstract::Diff->new(raw => $diff, project => $self->project);
}

sub build_added    { shift->x_changes->{added}    }
sub build_removed  { shift->x_changes->{removed}  }
sub build_modified { shift->x_changes->{modified} }
sub build_moved    { shift->x_changes->{moved}    }

sub build_x_changes {
    my $self = shift;
    my $proj_path = $self->project->repository->root . $self->project->name;
    my $xml_string = $self->project->repository->vci->x_do(
        args => [qw(log -v --xml), "-r" . $self->revision, $proj_path]);
    my $xs = XML::Simple->new(ForceArray => [qw(file directory)],
                              KeyAttr => []);
    my $xml = $xs->xml_in($xml_string);
    my $log = $xml->{log};
    # The format of the XML changed in xmloutput Revision 17.
    my $files = exists $log->{'affected-files'} ? $log->{'affected-files'}
                                                : $log;
    my (@added, @removed, @modified);
    if (exists $files->{added}) {
        @added = $self->_x_parse_items($files->{added}, $log);
    }
    if (exists $files->{removed}) {
        @removed = $self->_x_parse_items($files->{removed}, $log);
    }
    if (exists $files->{modified}) {
        @modified = $self->_x_parse_items($files->{modified}, $log);
    }
        
    my %moved;
    if (my $renamed = $files->{renamed}) {
        my @items;
        if (exists $renamed->{file}) {
            push(@items, @{$renamed->{file}});
        }
        if (exists $renamed->{directory}) {
            push(@items, @{$renamed->{directory}});
        }
     
        foreach my $item (@items) {
            my $old = $item->{oldpath};
            my $new = $item->{content};
            $moved{$new} = $old;
        }
    }
    
    return {
        added     => \@added,
        removed   => \@removed,
        modified  => \@modified,
        moved     => \%moved,
    };
}

sub _x_parse_items {
    my ($self, $items, $log) = @_;

    my @result;
    if (exists $items->{file}) {
        foreach my $file (@{ $items->{file} }) {
            # Have to "require" to avoid dep loops.
            require VCI::VCS::Bzr::File;
            push(@result, VCI::VCS::Bzr::File->new(
                path => $file, revision => $log->{revno},
                time => $log->{timestamp}, project => $self->project));
        }
    }
    if (exists $items->{directory}) {
        foreach my $dir (@{ $items->{directory} }) {
            require VCI::VCS::Bzr::Directory;
            push(@result, VCI::VCS::Bzr::Directory->new(
                path => $dir, revision => $log->{revno},
                time => $log->{timestamp}, project => $self->project));
        }
    }
    return @result;
}

__PACKAGE__->meta->make_immutable;

1;
