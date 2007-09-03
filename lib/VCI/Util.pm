package VCI::Util;
use Moose::Util::TypeConstraints;

use Carp qw(confess);
use DateTime;
use DateTime::Format::DateParse;
use Path::Abstract;
use Scalar::Util qw(blessed);

################
# Object Types #
################

subtype 'DateTime'
    => as 'Object'
    => where { $_->isa('DateTime') };

coerce 'DateTime'
    => from 'Num'
        => via { DateTime->from_epoch(epoch => $_) }
    => from 'Str'
        => via {
            my $result = DateTime::Format::DateParse->parse_datetime($_);
            if (!defined $result) {
                confess("Date::Parse failed to parse '$_' into a DateTime");
            }
            return $result;
        };

subtype 'Path'
    => as 'Object',
    => where { $_->isa('Path::Abstract') && $_->stringify !~ m|/\s*$|o };

coerce 'Path'
    => from 'Str'
        => via {
            $_ =~ s|/\s*$||o;
            Path::Abstract->new($_)->to_branch;
        }
    => from 'ArrayRef'
                # XXX This may not deal with trailing slashes properly.
        => via { Path::Abstract->new(@$_)->to_branch; }
    => from 'Object'
        => via { $_->to_branch };

###############
# Array Types #
###############

subtype 'ArrayOfChanges'
    => as 'ArrayRef'
    => where {
        foreach my $item (@$_) {
            return 0 if !(blessed($item)
                          && $item->isa('Text::Diff::Parser::Change'));
        }
        return 1;
    };

subtype 'ArrayOfCommits'
    => as 'ArrayRef'
    => where {
        foreach my $item (@$_) {
            return 0 if !(blessed($item)
                          && $item->isa('VCI::Abstract::Commit'));
        }
        return 1;
    };

subtype 'ArrayOfCommittables'
    => as 'ArrayRef'
    => where {
        foreach my $item (@$_) {
            return 0 if !(blessed($item)
                          && $item->does('VCI::Abstract::Committable'));
        }
        return 1;
    };

subtype 'ArrayOfHistories'
    => as 'ArrayRef'
    => where {
        foreach my $item (@$_) {
            return 0 if !(blessed($item)
                          && $item->isa('VCI::Abstract::History'));
        }
        return 1;
    };

subtype 'ArrayOfProjects'
    => as 'ArrayRef'
    => where {
        foreach my $item (@$_) {
            return 0 if !(blessed $item
                          && $item->isa('VCI::Abstract::Project'));
        }
        return 1;
    };

1;

__END__

=head1 NAME

VCI::Util - Types and Utility Functions used by VCI

=head1 DESCRIPTION

This contains mostly L<subtypes|Moose::Util::TypeConstraints/subtype> used
by accessors in various VCI modules.

=head1 TYPES

=head2 Arrays

All of these are extensions of the C<ArrayRef> type from
L<Moose::Util::TypeConstraints>.

=over

=item C<ArrayOfChanges>

An arrayref that can only contain
L<Text::Diff::Parser::Change|Text::Diff::Parser/CHANGE_METHODS> objects.

=item C<ArrayOfCommits>

An arrayref that can only contain L<VCI::Abstract::Commit> objects.

=item C<ArrayOfCommittables>

An arrayref that can only contain objects that implement
L<VCI::Abstract::Committable>.

=item C<ArrayOfContainers>

An arrayref that can only contain objects that implement
L<VCI::Abstract::FileContainer>.

=item C<ArrayOfProjects>

An arrayref that can only contain L<VCI::Abstract::Project> objects.

=back

=head2 Objects

=over

=item C<DateTime>

A L<DateTime> object.

If you pass in a number for this argument, it will be interpreted as
a Unix epoch (seconds since January 1, 1970) and converted to a DateTime
object using L<DateTime/from_epoch>.

If you pass in a string that's not just an integer, it will be parsed
by L<DateTime::Format::DateParse>.

=item C<Path>

A L<Path::Abstract> object.

If you pass a string for this argument, it will be converted using
L<Path::Abstract/new>. This means that paths are always Unix paths--the
path separator is always C</>. C<\path\to\file> will not work.

After processing, the path will never start with C</> and never end with
C</>. (In other words, it will always be a relative path and never end
with C</>.)

If you pass the root path (C</>) you will get an empty path.

=back
