package VCI::VCS::Hg::History;
use Moose;

use VCI::VCS::Hg::Commit;

extends 'VCI::Abstract::History';

sub x_from_rss {
    my ($class, $file, $project) = @_;
    my $xs = XML::Simple->new(ForceArray => [qw(item)],
                              KeyAttr => []);
    
    my (@commits, $last_rev_id);
    while (1) {
        my $these_commits = _x_get_rss_commits($project, $xs, $last_rev_id, $file);
        last if !scalar @$these_commits;
        $last_rev_id = $these_commits->[-1]->revision;
        push(@commits, @$these_commits);
    }
    @commits = reverse @commits;
    
    return $class->new(commits => \@commits, project => $project);
}

sub _x_get_rss_commits {
    my ($project, $xs, $rev_id, $file) = @_;
    $rev_id ||= 'tip';
    my @path = ('rss-log', $rev_id);
    push(@path, $file) if defined $file;
    my $rss = $project->x_get(\@path);
    my $xml = $xs->xml_in($rss);    
    my $items = $xml->{channel}->{item};
    if ($rev_id ne 'tip') {
        # We always get the $rev_id we requested as the first item, except
        # on the last page, where it could be the first, second, third, etc.
        # This code works correctly in all situations.
        while (my $first_item = shift(@$items)) {
            last if $first_item->{link} =~ /\Q$rev_id\E/;
        }
    }
    return [map { VCI::VCS::Hg::Commit->x_from_rss_item($_, $project) } @$items];
}

__PACKAGE__->meta->make_immutable;

1;
