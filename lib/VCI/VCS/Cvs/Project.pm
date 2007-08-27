package VCI::VCS::Cvs::Project;
use Moose;

use VCS::LibCVS;

extends 'VCI::Abstract::Project';

has 'x_directory' => (is => 'ro', isa => 'VCS::LibCVS::DirectoryBranch', lazy => 1,
                      default => sub { shift->build_x_directory });

sub build_x_directory {
    my $self = shift;
    
    my $project_root =
        VCS::LibCVS::RepositoryDirectory->new($self->repository->x_repo,
                                              $self->name);
    # XXX This currently limits us to branch support, no tags.
    my $tagspec = VCS::LibCVS::Datum::TagSpec->new("THEAD");
    my $branch_root =
        VCS::LibCVS::DirectoryBranch->new($project_root, $tagspec);

    return $branch_root;
}

1;
