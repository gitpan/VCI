#!/usr/bin/perl

use Module::Build;

use strict;
use warnings;

# If we don't require SVN::Core, Module::Build can't read its $VERSION.
eval { require SVN::Core };

my $build = Module::Build->new(
    module_name => 'VCI',
    license  => 'perl',
    create_makefile_pl => 'passthrough',
    requires => {
        'Moose'          => '0',
        'MooseX::Method' => '0',
        'DateTime'       => '0',
        'Path::Abstract' => '0',
        'DateTime::Format::DateParse' => '0',
        'Carp'           => '0',
    },
    build_requires => {
        'Test::More'      => '0',
        'Test::Exception' => '0',
    },
    auto_features => {
        bzr => {
            description => "Bazaar Support",
            requires => {
                'IPC::Cmd'    => 0,
                'XML::Simple' => 0,
            }
        },
        svn => {
            description => 'Subversion Support',
            requires => {
                'SVN::Core' => '1.1.0',
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
                'Git' => '0',
            }
        },
    },
);

$build->create_build_script;
