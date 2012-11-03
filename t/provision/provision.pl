#!/usr/bin/env perl
# dummy provision script just for testing
#
# prints all files in 'provision' dir and ENV like 'key: value'
#
use strict;
use warnings;
use FindBin;
use File::Find;

chdir $FindBin::Bin;
find sub { -f $_ and print "$File::Find::name\n" }, '.';

print for map "$_: $ENV{$_}\n", sort keys %ENV;

# a nonzero exit code for tests
exit 13;
