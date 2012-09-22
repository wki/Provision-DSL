#!/usr/bin/env perl
#
# test provisioning file which simply lists all files in its dir.
# using this simple script we can prove the existence of files
# for provisioning
#
use strict;
use warnings;
use FindBin;
use File::Find;

find(\&print_file, $FindBin::Bin);

sub print_file {
    return if !-f $_;
    print substr($File::Find::name, length($FindBin::Bin)+1) . "\n";
}
