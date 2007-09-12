package VCI::VCS::Svn::File;
use Moose;

with 'VCI::VCS::Svn::Committable';
extends 'VCI::Abstract::File';

# XXX Must implement this.
sub build_is_executable { undef }

# We have to do this because ->isa File or Directory never
# returns true on a FileOrDirectory.
sub _me_from {
    my $self = shift;
    my $orig_class = blessed $self;
    bless $self, 'VCI::VCS::Svn::FileOrDirectory';
    my $ret = $self->SUPER::_me_from(@_);
    bless $self, $orig_class;
    bless $ret, $orig_class;
    return $ret;
};

__PACKAGE__->meta->make_immutable;

1;
