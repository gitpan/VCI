package VCI::VCS::Bzr::History;
use Moose;

use XML::Simple;
use VCI::VCS::Bzr::Commit;
use VCI::VCS::Bzr::File;

extends 'VCI::Abstract::History';

sub x_from_xml {
    my ($class, $xml_string, $project) = @_;
    # XXX We *really* need to do this with SAX, for performance reasons.
    my $xs = XML::Simple->new(ForceArray => [qw(file directory log)],
                              KeyAttr => []);
    my $xml = $xs->xml_in($xml_string);
    
    my @commits;
    foreach my $log (@{$xml->{log}}) {
        # The format of the XML changed in xmloutput Revision 17.
        my $files = exists $log->{'affected-files'} ? $log->{'affected-files'}
                                                    : $log;
        my (@added, @removed, @modified);
        if (exists $files->{added}) {
            @added = _x_parse_items($files->{added}, $log, $project);
        }
        if (exists $files->{removed}) {
            # XXX Is this the right XML?
            @removed = _x_parse_items($files->{removed}, $log, $project);
        }
        if (exists $files->{modified}) {
            @modified = _x_parse_items($files->{modified}, $log, $project);
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
        
        $log->{message} ||= '';
        chomp($log->{message});
        # For some reason bzr adds a single space to the start of messages
        # in XML format.
        $log->{message} =~ s/^ //;
        
        my $commit = VCI::VCS::Bzr::Commit->new(
            revision  => $log->{revno},
            committer => $log->{committer},
            time      => $log->{timestamp},
            message   => $log->{message},
            added     => \@added,
            removed   => \@removed,
            modified  => \@modified,
            moved     => \%moved,
            project   => $project,
        );
        
        push(@commits, $commit);
    }
    
    return $class->new(commits => [reverse @commits], project => $project);
}

sub _x_parse_items {
    my ($items, $log, $project) = @_;

    my @result;
    if (exists $items->{file}) {
        foreach my $file (@{ $items->{file} }) {
            push(@result, VCI::VCS::Bzr::File->new(
                path => $file, revision => $log->{revno},
                time => $log->{timestamp}, project => $project));
        }
    }
    if (exists $items->{directory}) {
        foreach my $dir (@{ $items->{directory} }) {
            push(@result, VCI::VCS::Bzr::Directory->new(
                path => $dir, revision => $log->{revno},
                time => $log->{timestamp}, project => $project));
        }
    }
    return @result;
}

__PACKAGE__->meta->make_immutable;

1;
