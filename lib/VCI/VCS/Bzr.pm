package VCI::VCS::Bzr;
use Moose;
use MooseX::Method;

use VCI::Util qw(taint_fail);
use VCI::VCS::Bzr::Repository;

use IPC::Cmd;
use Scalar::Util qw(tainted);

extends 'VCI';

our $VERSION = '0.4.0_1';

# The path to the bzr binary.
has 'x_bzr' => (is => 'ro', isa => 'Str',
                default => sub { shift->_build_x_bzr });

sub BUILD {
    my $self = shift;
    taint_fail("The x_bzr argument '$self->{x_bzr}' is tainted")
        if tainted($self->{x_bzr});
}

sub _build_x_bzr {
    my $cmd = IPC::Cmd::can_run('bzr')
        || confess('Could not find "bzr" in your path');
    taint_fail("We found '$cmd' for bzr, but that string is tainted."
               . ' This probably means $ENV{PATH} is tainted')
        if tainted($cmd);
    return $cmd;
}

method 'x_do' => named (
    args          => { isa => 'ArrayRef', required => 1 },
    errors_undef  => { isa => 'ArrayRef', default => [] },
    errors_ignore => { isa => 'ArrayRef', default => [] },
    errors_undef_regex  => { isa => 'RegexpRef' },
    errors_ignore_regex => { isa => 'RegexpRef' },
) => sub {
    my ($self, $params) = @_;
    my $args = $params->{args};
    
    my $full_command = $self->x_bzr . ' ' . join(' ', @$args);
    if ($self->debug) {
        print STDERR "Command: $full_command\n";
    }
    
    # See http://rt.cpan.org/Ticket/Display.html?id=31738
    local $IPC::Cmd::USE_IPC_RUN = 1;
    
    my ($success, $errorcode, $all, $stdout, $stderr) =
        IPC::Cmd::run(command => [$self->x_bzr, @$args]);
        
    print STDERR "Exit Code: $errorcode\n" if $self->debug;
    
    if (!$success) {
        my $err_string = join('', @$stderr);
        
        if (!grep {$_ == $errorcode} @{$params->{errors_ignore}}) {
            my $re = $params->{errors_undef_regex};
            if (grep {$_ == $errorcode} @{$params->{errors_undef}}
                || (defined $re && $err_string =~ $re))
            {
                return undef;
            }
            
            my $ignore_re = $params->{errors_ignore_regex};
            unless (defined $ignore_re && $err_string =~ $ignore_re) {
                my $error_output = join('', @$stderr);
                chomp($error_output);
                confess("$full_command failed: $error_output");
            }
        }
    }
    
    my $output_string = join('', @$stdout);
    chomp($output_string);
    if ($self->debug > 1) {
            print STDERR "Results:\n" . join('', @$all);
    }
    return $output_string;
};

1;

__END__

=head1 NAME

VCI::VCS::Bzr - The Bazaar implementation of VCI

=head1 DESCRIPTION

This is a "driver" for L<VCI> for the Bazaar version-control system.
You can find out more about Bazaar at L<http://bazaar-vcs.org>.

For information on how to use VCI::VCS::Bzr, see L<VCI>.

=head1 CONNECTING TO A BZR REPOSITORY

For the L<repo|VCI/repo> argument to L<VCI/connect>, choose the directory
above where your branches are kept. For example, if I have a branch
C<http://bzr.domain.com/bzr/branch>, then the C<repo> would be
C<http://bzr.domain.com/bzr/>.

Bzr's C<connect> also takes one optional extra argument:

=over

=item C<x_bzr>

The path to the C<bzr> binary on your system. If not specified, we will
search your C<PATH> and throw an error if C<bzr> isn't found.

B<Taint Mode>: VCI will throw an error if this argument is tainted,
because VCI just runs this command blindly, and we wouldn't want
to run something like C<delete_everything_on_this_computer.sh>.

=back

=head1 REQUIREMENTS

VCI::VCS::Bzr requires that the following be installed on your system:

=over

=item bzr

C<bzr> Must be installed and accessible to VCI. If it's not in your path,
you should specify an C<x_bzr> argument to L<VCI/connect>, which should
contain the full path to the C<bzr> executable, such as F</usr/bin/bzr>.

=item bzrtools

The C<bzrtools> extension package must be installed. Usually this is
available as a package (RPM or deb) in your distrubution, or you can
download it from here: L<http://bazaar-vcs.org/BzrTools>.

=item bzr-xmloutput

Because VCI::VCS::Bzr processes the output of bzr, it needs it in a
machine-readable format like XML. For bzr, this is accomplished by the
C<bzr-xmloutput> plugin, which is available here:
L<https://launchpad.net/bzr-xmloutput>.

You can read about how to install it at L<http://bazaar-vcs.org/UsingPlugins>.

=back

This is in addition to any perl module requirements listed when you install
VCI::VCS::Bzr.

=head1 LIMITATIONS AND EXTENSIONS

These are limitations of VCI::VCS::Bzr compared to the general API specified
in the C<VCI::Abstract> modules.

=head2 VCI::VCS::Bzr::Repository

=over

=item C<projects>

On some repositories, L<"projects"|VCI::Abstract::Repository/projects>
will return an empty array, even though there are branches there. This only
happens for repositories where we can't list the directories. For example,
HTTP repositories without a directory listing.

However, L<get_project|VCI::Abstract::Repository/get_project> will still
work on those repositories.

=back

=head2 VCI::VCS::Bzr::Directory

When constructing a Directory, you cannot specify C<time> or C<revision>
without also specifying C<contents>. VCI::VCS::Bzr itself never does this,
so you generally don't have to worry about this unless you're building
your own objects for some reason.

=head1 PERFORMANCE

With local repositories, VCI::VCS::Bzr should be very fast. With
remote repositories, certain operations may be slow, such as
calling C<projects> on a Repository.

=head1 SEE ALSO

L<VCI>

=head1 BUGS

VCI::VCS::Bzr is very new, and may have significant bugs. The code is
alpha-quality at this point.

=head1 AUTHOR

Max Kanat-Alexander <mkanat@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2008 by Everything Solved, Inc.

L<http://www.everythingsolved.com>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
