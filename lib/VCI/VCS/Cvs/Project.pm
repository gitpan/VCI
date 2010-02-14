package VCI::VCS::Cvs::Project;
use Moose;
use MooseX::Method;

use IPC::Cmd;
use File::Temp qw(tempdir);
use File::Path;

use VCI::Util;
use VCI::VCS::Cvs::File;
use VCI::VCS::Cvs::Commit;
use VCI::VCS::Cvs::History;

extends 'VCI::Abstract::Project';

# XXX If this string shows up in a log message, that could mess up our parsing.
use constant CVSPS_SEPARATOR => "\n\n---------------------\n";
use constant CVSPS_PATCHSET  => qr/
^PatchSet\s(\d+)\s?\n
Date:\s(\S+\s\S+)\n
Author:\s(\S+)\n
Branch:\s\S+\n
Tag:\s[^\n]+\s?\n
(?:Branches:[^\n]\n)?
Log:\n
(.*)\n
\n
Members:\s?\n
(.*)$
/sox;

use constant CVSPS_MEMBER => qr/^\s+(.+):(INITIAL|[\d\.]+)->([\d\.]+)(\(DEAD\))?/o;

has 'x_tmp' => (is => 'ro', isa => 'Str', lazy => 1,
                default => sub { tempdir('vci.cvs.XXXXXX', TMPDIR => 1,
                                         CLEANUP => 1) });

sub BUILD {
    my $self = shift;
    $self->_name_never_ends_with_slash();
    $self->_name_never_starts_with_slash();
}

method 'get_file' => named (
    path     => { isa => 'VCI::Type::Path', coerce => 1, required => 1 },
    revision => { isa => 'Str' },
) => sub {
    my $self = shift;
    my ($params) = @_;
    my $path = $params->{path};
    my $rev  = $params->{revision};
    
    confess("Empty path name passed to get_file") if $path->is_empty;
    
    if (defined $rev) {
        my $file = VCI::VCS::Cvs::File->new(path => $path, revision => $rev,
                                            project => $self);
        # If $file->time works, then we have a valid file & revision.
        return $file if defined eval { $file->time };
        undef $@; # Don't mess up anything else that checks $@.
        return undef;
    }
    
    # MooseX::Method always has a hash key for each parameter, even if they
    # weren't passed by the caller.
    delete $params->{$_} foreach (grep(!defined $params->{$_}, keys %$params));
    return $self->SUPER::get_file(@_);
};

sub _build_history {
    my $self = shift;
    my $stdout = $self->x_cvsps_do();

    my @commits;
    # The \n\n makes the split work more easily.
    $stdout = "\n\n$stdout";
    my @patchsets = split(CVSPS_SEPARATOR, $stdout);
    shift @patchsets; # The first item will be empty.
    foreach my $patchset (@patchsets) {
        if ($patchset =~ CVSPS_PATCHSET) {
            my ($revision, $date, $author, $message, $members) =
                ($1, $2, $3, $4, $5);
            my (@added, @removed, @modified);
            foreach my $item (split("\n", $members)) {
                if ($item =~ CVSPS_MEMBER) {
                    my ($path, $from_rev, $to_rev, $dead) = ($1, $2, $3, $4);
                    my $file = VCI::VCS::Cvs::File->new(
                        path => $path, revision => $to_rev, project => $self,
                        time => "$date UTC");
                    if ($from_rev eq 'INITIAL') {
                        push(@added, $file);
                    }
                    elsif ($dead) {
                        push(@removed, $file);
                    }
                    else {
                        push(@modified, $file);
                    }
                }
                else {
                    warn "Failed to parse message item: [$item] for patchset"
                         . " $revision";
                }
            }
            
            push(@commits, VCI::VCS::Cvs::Commit->new(revision => $revision,
                time => "$date UTC", added => \@added, removed => \@removed,
                modified => \@modified, committer => $author,
                message => $message, project => $self));
        }
        else {
            warn "Patchset cannot be parsed:\n" . $patchset;
        }
    }
    
    return VCI::VCS::Cvs::History->new(commits => \@commits, project => $self);
}

sub x_cvsps_do {
    my ($self, $addl_args) = @_;
    $addl_args ||= [];
    my @args = (@$addl_args, '-u', '-b', 'HEAD', $self->name);
    # Just using the --root argument of cvsps doesn't work.
    my $root = $self->repository->root;
    my $cvsps = $self->repository->vci->x_cvsps;
    
    if ($self->repository->vci->debug) {
        print STDERR "Running CVSROOT=$root $cvsps " . join(' ', @args)
                     . "\n";
    }
    
    local $ENV{CVSROOT} = $root;
    local $ENV{TZ} = 'UTC';
    # See http://rt.cpan.org/Ticket/Display.html?id=31738
    local $IPC::Cmd::USE_IPC_RUN = 1;
    # XXX cvsps must be able to write to $HOME or this will fail.
    my ($success, $error_msg, $all, $stdout, $stderr) =
        IPC::Cmd::run(command => [$self->repository->vci->x_cvsps, @args]);
    if (!$success) {
        confess("$error_msg: $stderr");
    }
    
    return join('', @$stdout);
}

sub DEMOLISH {
    File::Path::rmtree($_[0]->x_tmp) if $_[0]->{x_tmp};
}

1;
