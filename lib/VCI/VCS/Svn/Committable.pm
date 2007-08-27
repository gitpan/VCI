package VCI::VCS::Svn::Committable;
use Moose::Role;
use Moose::Util::TypeConstraints;

# We could make this not required and build it with $ctx->info, but I want
# it to be required right now to make sure I don't forget to add it while
# constructing objects.
has 'x_info' => (is => 'ro', isa => 'SVN_Info', lazy => 1,
                 default => sub { shift->build_x_info });

subtype 'SVN_Info'
    => as 'Object'
    => where { $_->isa('_p_svn_dirent_t') || $_->isa('_p_svn_info_t') };

sub BUILD {
    my $self = shift;
    if (!defined $self->{x_info} && !defined $self->{revision}) {
        confess("You must define x_info if you don't define revision");
    }
}

sub build_revision {
    my $info = shift->x_info;
    if ($info->isa('_p_svn_info_t')) {
        return $info->last_changed_rev;
    }
    return $info->created_rev;
}

sub build_time {
    my $info = shift->x_info;
    if ($info->isa('_p_svn_info_t')) {
        return $info->last_changed_date;
    }
    return $info->time;
}

# This is mostly used to build "time" if you don't specify it during
# construction.
sub build_x_info {
    my $self = shift;
    my $ctx = $self->repository->vci->x_client;
    my $info;
    # XXX Need to check return for errors.
    my $full_path = Path::Abstract->new($self->name, $self->path);
    $ctx->info($self->repository->root . $full_path->stringify,
               undef, $self->revision, sub { $info = $_[1] }, 0);
    return $info;
}

1;
