package VCI::Abstract::Repository;
use Moose;
use MooseX::Method;

use VCI::Util;

has 'root'     => (is => 'ro', isa => 'Str', required => 1);
has 'projects' => (is => 'ro', isa => 'ArrayOfProjects', lazy => 1,
                   default => sub { shift->build_projects });
has 'vci'      => (is => 'ro', isa => 'VCI', required => 1);

method 'get_project' => named (
    name   => { isa => 'Str', required => 1 },
) => sub {
    my ($self, $params) = @_;
  
    return $self->vci->project_class->new(
        name => $params->{name}, repository => $self);
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

VCI::Abstract::Repository - A repository where version-controlled items are kept.

=head1 SYNOPSIS

 my $repo = VCI->connect(...); # See VCI.pm for details.
 
 my $projects = $repo->projects;
 my $project = $repo->get_project(name => 'Foo');

=head1 DESCRIPTION

As mentioned in L<VCI>, a Repository is a "server" where files are stored
by your version-control system.

In some VCSes, it's not really a "server", it's just a directory that contains
Projects.

=head1 METHODS

=head2 Accessors

All these accessors are read-only.

=over

=item C<root>

A string representing the "root" of this repository, in the same format
that you'd pass into the command-line client for your VCS. The individual
implementations of L<VCI::Abstract::Repository> will describe the format
of this string in more detail.

=item C<projects>

An arrayref of every L<VCI::Abstract::Project> in this repository. In
some VCSes, this may just be the projects in the root directory
of the repository, or something that doesn't entirely describe
I<everything> that's tracked in the system.

=item C<vci>

The L<VCI> that connected to this repository. In general, unless you're
a L<VCI> implementor, you probably don't care about this.

=back

=head2 Convenience Methods

These are methods that are easier to use or more efficient than the
accessors above, when you only need to do particular things.

=over

=item C<get_project>

=over

=item B<Description>

Gets a single L<VCI::Abstract::Repository> from the repository, by name.

=item B<Parameters>

Takes the following named parameters:

=over

=item C<name> - The unique name of this Project. Something that uniquely
identifies this project in the version control system. Usually, this is just
the name of the directory that contains the Project, from the root of the
repository.

(For example, C<mozilla/webtools/bugzilla> is the "name" of the Bugzilla
project inside of the Mozilla CVS Server.)

=back

=item B<Returns>

The L<VCI::Abstract::Project> that you asked for, or C<undef> if the
Project does not exist in the repository.

If there was some other error than that the Project doesn't exist, this
method will C<die>.

=back

=back

=head1 CLASS METHODS

=head2 Constructors

Usually you won't construct an instance of this class directly, but
instead, use L<VCI/connect> to get a Repository object.

=over

=item C<new>

Takes all L</Accessors> of this class as named parameters. The following
fields are B<required>: L</root> and L</vci>.

=back