package VCI::VCS::Cvs::Repository;
use Moose;
use MooseX::Method;

use VCI::VCS::Cvs::Project;

# XXX projects() currently isn't implemented yet.

extends 'VCI::Abstract::Repository';

has 'x_repo' => (is => 'ro', isa => 'VCS::LibCVS::Repository', required => 1);
has 'x_root_dir' => (is => 'ro', isa => 'VCS::LibCVS::RepositoryDirectory',
                     default => sub { VCS::LibCVS::RepositoryDirectory->new(
                                        shift->x_repo, '.') });

# XXX get_project Doesn't support modules yet.
# For get_project module support, all paths will be from the root of the
# repository. But for directory support, they will be from the root
# of the directory. Can do "cvs co -c" to get modules.

1;
