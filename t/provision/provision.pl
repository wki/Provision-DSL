#!/usr/bin/env perl
# dummy provision script just for testing
#
# prints all files in 'provision' dir and ENV like 'key: value'
#
use strict;
use warnings;
use feature ':5.10';
use FindBin;
use File::Find;

chdir $FindBin::Bin;
find sub { -f $_ and say $File::Find::name }, '.';

say for map { "$_: $ENV{$_}" } sort keys %ENV;
