package VCI::Abstract::Repository;
use Moose;
use MooseX::Method;

use VCI::Abstract::Project;
use VCI::Util;

has 'root'     => (is => 'ro', isa => 'Str', required => 1);
has 'projects' => (is => 'ro', isa => 'ArrayOfProjects', lazy => 1,
                   default => sub { shift->build_projects });
has 'vci'      => (is => 'ro', isa => 'VCI', required => 1);
has 'root_project' => (is => 'ro', isa => 'VCI::Abstract::Project | Undef',
                       lazy => 1, default => sub { shift->build_root_project });

method 'get_project' => named (
    name   => { isa => 'Str', required => 1 },
) => sub {
    my ($self, $params) = @_;
  
    return $self->vci->project_class->new(
        name => $params->{name}, repository => $self);
};

sub build_root_project { return undef; }

####################
# Subclass Helpers #
####################

# For use in BUILD
sub _root_always_ends_with_slash {
    my $self = shift;
    $self->_root_never_ends_with_slash;
    $self->{root} .= '/';
}
sub _root_never_ends_with_slash  { $_[0]->{root} =~ s|/\s*$|| }

# To implement build_root_project for VCSes that support it.
sub _root_project {
    return $_[0]->vci->project_class->new(repository => $_[0], name => '');
}

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

=item C<root_project>

In some VCSes, the whole Repository can be viewed as one big Project.
If that works for your VCS, then this returns a L<VCI::Abstract::Project>
that represents the "root directory" of the Repository.

If your VCS does not support this, C<root_project> returns C<undef>. That
means that B<all users of> C<root_project> B<must check if it returns>
C<undef>.

Generally, "directory based" VCSes like CVS and Subversion support
C<root_project>, and other VCSes don't.

The "LIMITATIONS AND EXTENSIONS" section of your driver's documentation will
say if it supports this method. By default, drivers don't support it, so if
the driver's documentation doesn't say anything about it, then you can
assume it will return C<undef> on that version-control system.

=item C<vci>

The L<VCI> that connected us to this repository. In general, unless you're
a L<VCI> implementor, you probably don't care about this.

=back

=head2 Getting a Project

=over

=item C<get_project>

=over

=item B<Description>

Gets a single L<VCI::Abstract::Project> from the repository, by name.

=item B<Parameters>

Takes the following named parameters:

=over

=item C<name>

The unique name of this Project. Something that uniquely
identifies this project in the version control system. Usually, this is just
the name of the directory that contains the Project, from the root of the
repository.

(For example, C<mozilla/webtools/bugzilla> is the "name" of the Bugzilla
project inside of the Mozilla CVS Server.)

=back

=item B<Returns>

The L<VCI::Abstract::Project> that you asked for. Most VCI::VCS
implementations will return a valid Project object even if that
object doesn't exist in the Repository. The only way to know if
a Project is valid is to perform some operation on it.

Some VCI::VCS implementations may C<die> message if you request an
invalid Project.

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