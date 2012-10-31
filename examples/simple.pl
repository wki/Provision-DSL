#!/usr/bin/env perl
#
# simple provision file for standalone usage
#     provision.pl user@hostname simple.pl
#
use Provision::DSL;

File "$ENV{HOME}/testme" => {
    content => 'Foo',
};

Done;
