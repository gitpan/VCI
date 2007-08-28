package VCI::VCS::Cvs::Project;
use Moose;

use IPC::Cmd;
use File::Temp qw(tempdir);
use File::Path;

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

sub build_history {
    my $self = shift;
    
    my @args = ('-b HEAD', $self->name);
    # Just using the --root argument of cvsps doesn't work.
    my $root = $self->repository->root;
    my $cvsps = $self->repository->vci->x_cvsps;
    if ($self->repository->vci->debug) {
        print STDERR "Running TZ=UTC CVSROOT=$root $cvsps " . join(' ', @args)
                     . "\n";
    }
    
    local $ENV{CVSROOT} = $root;
    # XXX cvsps must be able to write to $HOME or this will fail.
    my ($success, $errorcode, $all, $stdout, $stderr) =
        IPC::Cmd::run(command => [$self->repository->vci->x_cvsps, @args]);
    if (!$success) {
        confess("cvsps failed with exit code $errorcode: $stderr");
    }
    
    my @commits;
    # The \n\n makes the split work more easily.
    $stdout = "\n\n" . join("", @$stdout);
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
                        time => $date);
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
                time => $date, added => \@added, removed => \@removed,
                modified => \@modified, committer => $author,
                message => $message, project => $self));
        }
        else {
            warn "Patchset cannot be parsed:\n" . $patchset;
        }
    }
    
    return VCI::VCS::Cvs::History->new(commits => \@commits, project => $self);
}

sub DEMOLISH {
    File::Path::rmtree($_[0]->x_tmp) if $_[0]->{x_tmp};
}

1;
