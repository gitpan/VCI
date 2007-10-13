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
            project   => $project,
        );
        
        push(@commits, $commit);
    }
    
    return $class->new(commits => [reverse @commits], project => $project);
}


__PACKAGE__->meta->make_immutable;

1;
