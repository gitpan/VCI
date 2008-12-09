#!/usr/bin/perl

use Module::Build;

use strict;
use warnings;

# If we don't require SVN::Core, Module::Build can't read its $VERSION.
eval { require SVN::Core };

my $class = Module::Build->subclass(
    class => 'Module::Build::VCI',
    code => <<'EOT' );

sub ACTION_dist {
    my $self = shift;
    $self->ACTION_manifest(@_);
    $self->ACTION_test(@_);
    $self->ACTION_manifest(@_);
    $self->SUPER::ACTION_dist(@_);
}
EOT

my $build = $class->new(
    module_name => 'VCI',
    license  => 'perl',
    create_makefile_pl => 'passthrough',
    requires => {
        'perl'           => '5.006',
        'Moose'          => '0.27',
        'MooseX::Method' => '0',
        'DateTime'       => '0',
        # This was when Underload was introduced.
        'Path::Abstract' => '0.093',
        'DateTime::Format::DateParse' => '0',
        # 0.06 has a bug with diff formats that lack a "diff file1 file2"
        # header.
        'Text::Diff::Parser' => '0.07',
        'Carp'           => '0',
    },
    # For right now I added all the auto_features to recommends that are
    # on CPAN, in the hope that CPAN-Testers will now be more likely to
    # run all the test code.
    recommends => {
        'IPC::Cmd'       => 0,
        'Module::Load::Conditional' => 0.24, # For taint safety in IPC::Cmd.
        'IPC::Run'       => 0.55,
        'XML::Simple'    => 0,
        'LWP::UserAgent' => 0,
        'Cwd'        => 0,
        'File::Path' => 0,
        'File::Temp' => 0,
        'List::Util' => 0,        
    },
    build_requires => {
        'Test::More'      => '0',
        'Test::Exception' => '0',
        'Test::Warn'      => '0',
        'File::Spec'      => '0',
    },
    auto_features => {
        bzr => {
            description => "Bazaar Support",
            requires => {
                'IPC::Cmd'    => 0,
                'Module::Load::Conditional' => 0.24,
                'IPC::Run'    => 0.55,
                'XML::Simple' => 0,
            }
        },
        svn => {
            description => 'Subversion Support',
            requires => {
                'Cwd' => 0,
                'SVN::Core' => '1.2.0',
            }
        },
        hg => {
            description => 'Mercurial Support',
            requires => {
                'LWP::UserAgent' => '0',
                'XML::Simple' => '0',
            }
        },
        git => {
            description => 'Git Support',
            requires => {
                'Cwd' => '0',
                'Git' => '0',
            }
        },
        cvs => {
            description => 'CVS Support',
            requires => {
                'IPC::Cmd'   => 0,
                'Module::Load::Conditional' => 0.24, # For taint safety in IPC::Cmd.
                'IPC::Run'   => 0.55,
                'Cwd'        => 0,
                'File::Path' => 0,
                'File::Temp' => 0,
                'List::Util' => 0,
            }
        },
    },
    meta_merge => {
        resources => {
            homepage   => 'http://vci.everythingsolved.com/',
            repository => 'http://bzr.everythingsolved.com/vci/'
        },
    },
);

$build->create_build_script;
