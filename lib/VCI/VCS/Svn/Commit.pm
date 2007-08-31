package VCI::VCS::Svn::Commit;
use Moose;

use VCI::VCS::Svn::FileOrDirectory;

extends 'VCI::Abstract::Commit';

sub x_from_log {
    my ($class, $project, $paths, $revno, $who, $when, $message) = @_;
    my %copied;
    my %actions = ('A' => [], 'D' => [], 'M' => []);
    foreach my $name (keys %$paths) {
        my $item = $paths->{$name};
        my $project_path = $project->name;
        
        # Get just the "path" part of the path, without the Project path.
        # We do this directly with a regex instead of with Path::Abstract,
        # because Path::Abstract was a major performance bottleneck in tests
        # here.
        my $path = $name;
        $path =~ s|^/?\Q$project_path\E/?||;
        
        my $from_path = $item->copyfrom_path;
        if ($from_path) {
            my $from_parent = Path::Abstract->new($from_path);
            my $from_longer = scalar($from_parent->list)
                              - scalar($project_path->list);
            my $from_file   = $from_parent->pop($from_longer);
            
            # $from_parent is now just the "project" part of the path. Let's
            # normalize it for comparison purposes.
            $from_parent = $from_parent->to_branch;
            
            # We were either copied from this project or a different one.
            my $project_from = $project;
            if ($from_parent->path->stringify ne $project_path) {
                # We just use the very first directory as the name of the
                # project we copied from. There's no way to know what part
                # of the path represents the branch.
                my $full_path = Path::Abstract->new($from_path);
                my $proj_from_name = ($full_path->list)[0];
                $project_from =
                    $project->repository->get_project(name => $proj_from_name);
                $from_file = Path::Abstract->new(($full_path->list)[1..-1]);
            }
            my $copied_from = VCI::VCS::Svn::FileOrDirectory->new(
                path => $from_file, project => $project_from,
                revision => $item->copyfrom_rev);
            $copied{$path} = $copied_from;
        }
        
        my $obj = VCI::VCS::Svn::FileOrDirectory->new(
            path => $path, project => $project,
            revision => $revno, time => $when);
        my $action = $paths->{$name}->action;
        if ($action eq 'R') {
            push(@{ $actions{'A'} }, $obj);
            # XXX Perhaps this should actually contain the removed revision?
            #     That's tricky, though.
            push(@{ $actions{'D'} }, $obj);
        }
        else {
            push(@{$actions{$action}}, $obj);
        }
    }
    
    return $class->new(
        revision  => $revno,
        time      => $when,
        committer => $who,
        message   => $message,
        added     => $actions{'A'},
        removed   => $actions{'D'},
        modified  => $actions{'M'},
        copied    => \%copied,
        project   => $project,
    );
}

__PACKAGE__->meta->make_immutable;

1;
