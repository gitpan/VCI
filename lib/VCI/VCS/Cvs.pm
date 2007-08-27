package VCI::VCS::Cvs;
use Moose;

use VCS::LibCVS;
use VCI::VCS::Cvs::Repository;

extends 'VCI';

our $VERSION = '0.0.0_1';

sub build_repository {
    my $self = shift;
    my $cvs_repo = VCS::LibCVS::Repository->new($self->repo);
    # Try to connect
    my $version = $cvs_repo->get_version();
    (print STDERR "Connected to $version\n") if $self->debug;
    
    return VCI::VCS::Cvs::Repository->new(
        root => $self->repo, vci => $self, x_repo => $cvs_repo);
}

1;
