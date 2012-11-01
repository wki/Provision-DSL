#!/usr/bin/env perl
#
# simple provision file for standalone usage without requiring privileges
#
#     provision.pl user@hostname simple.pl
#
use Provision::DSL;

File "$ENV{HOME}/testme" => {
    content => 'Foo',
};

Done;
