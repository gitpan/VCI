package VCI::VCS::Hg::Committable;
use Moose::Role;

use DateTime;

sub BUILD {
    my $self = shift;
    # This condition is because I don't know of any way to get a revision
    # number from hgweb if provided with just a time.
    if (defined $self->{time} && !defined $self->{revision}) {
        confess("You cannot build a Hg Committable that has its time"
                . " defined but not its revision.");
    }
}

# Anything without a revision specified is "tip".
sub build_revision { return 'tip' }

sub build_time {
    my $self = shift;
    my $text = $self->project->x_get(['raw-rev', $self->revision]);
    $text =~ /^# Date (\d+) (-)?(\d{4})$/ms;
    my ($time, $minus, $offset_seconds) = ($1, $2, $3);
    my $offset_hours    = $offset_seconds / 3600;
    my $offset_fraction = $offset_hours - int($offset_hours);
    my $offset_minutes  = $offset_fraction * 60;
    # Minus means plus, and absence of minus means...minus.
    my $direction = $minus ? '+' : '-';
    my $zone = $direction . sprintf('%02u%02u', $offset_hours, $offset_minutes);
    return DateTime->from_epoch(epoch => $time, time_zone => $zone);
}

1;
