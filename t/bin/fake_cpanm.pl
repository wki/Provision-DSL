#!/usr/bin/env perl
# fake cpanm.
# create a file containing @ARGV at a location where an installed perl module
# would reside
#
# usage: fake_cpanm ... -L /path/to/lib ... Perl::Module

use strict;
use warnings;
use Getopt::Std;
use Path::Class;

my $args = join(' ', @ARGV);

my %opts;
getopt('L:', \%opts);

my $module = $ARGV[-1];
my $lib_dir = dir($opts{L});
my $install_dir = $lib_dir->subdir('lib/perl5');
$install_dir->mkpath if !-d $install_dir;

my $pm_file = $install_dir->file(split /::/, "$module.pm");
$pm_file->dir->mkpath if !-d $pm_file->dir;
$pm_file->spew($args);
