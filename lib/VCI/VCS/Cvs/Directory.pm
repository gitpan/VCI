package VCI::VCS::Cvs::Directory;
use Moose;
extends 'VCI::Abstract::Directory';

use File::Path qw(mkpath);
use List::Util qw(maxstr);
use Path::Abstract;

use VCI::VCS::Cvs::File;

has 'x_cvs_dir' => (is => 'ro', isa => 'Str', lazy => 1,
                    default => sub { shift->build_x_cvs_dir });

sub build_revision { 'HEAD' }

# XXX This should be optimized.
sub build_time {
    my $self = shift;
    my @files = grep($_->isa('VCI::Abstract::File'), @{$self->contents});
    my @times = map { $_->time } @files;
    return maxstr(@times) || 0;
}

# XXX Currently this may not return things with the proper revision.
sub build_contents {
    my $self = shift;
    my $output = $self->project->repository->vci->x_do(
        args    => ['-n', 'update', '-d'],
        fromdir => $self->x_cvs_dir);
    my @lines = split("\n", $output);
    my @contents;
    foreach my $line (@lines) {
        next if  $line =~ /^cvs update: Updating \.$/;
        if ($line =~ /^U (.*)$/) {
            my $path = Path::Abstract->new($self->path, $1);
            push(@contents, VCI::VCS::Cvs::File->new(
                path => $path, project => $self->project,
                parent => $self));
        }
        elsif ($line =~  /New directory .(.+). -- ignored$/) {
            my $path = Path::Abstract->new($self->path, $1);
            push(@contents, VCI::VCS::Cvs::Directory->new(
                path => $path, project => $self->project,
                parent => $self));
        }
        else {
            warn "Unparseable line during contents: $line";
        }
    }
    return \@contents;
}

# CVS doesn't really support listing files and directories from a remote
# connection. However, we can trick it into doing so with fake "CVS" dirs.
sub build_x_cvs_dir {
    my $self = shift;
    my $dir = Path::Abstract->new($self->project->x_tmp, $self->path);
    my $cvsdir = Path::Abstract->new($dir, 'CVS')->stringify;
    if (!-d $cvsdir) {
        mkpath($cvsdir);
    
        open(my $root, ">$cvsdir/Root")
            || confess "Failed to open $cvsdir/Root: $!";
        print $root $self->project->repository->root;
        close($root);
        
        my $repo_name = $self->project->name . '/' . $self->path->stringify;
        # For local repos, you have to specify the full absolute path.
        if ($self->project->repository->x_is_local) {
            $repo_name = $self->project->repository->x_dir_part . '/' . $repo_name;
        }
        open(my $repository, ">$cvsdir/Repository")
            || confess "Failed to open $cvsdir/Repository: $!";
        print $repository $repo_name;
        close($repository);
        
        # Create a blank Entries file, or CVS complains.
        open(my $entries, ">$cvsdir/Entries")
            || confess "Failed to create $cvsdir/Entries: $!";;
        close($entries);
    }
    return $dir->stringify;
}

sub DEMOLISH {
    my $self = shift;
    File::Path::rmtree($self->x_cvs_dir) if defined $self->{x_cvs_dir};
}

__PACKAGE__->meta->make_immutable;

1;
