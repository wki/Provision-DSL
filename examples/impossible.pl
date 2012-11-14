#!/usr/bin/env perl
#
# just an example. The last executed entity requests a Url() which
# could get provided if the former entities are installed properly
# just to debug and improve this situation
#
#     provision.pl user@hostname impossible.pl
#
use Provision::DSL;

File "$ENV{HOME}/impossible1.txt" => {
    content => 'Foo',
};

File "$ENV{HOME}/impossible2.txt" => {
    content => Url('http://localhost:3030/nonsense.txt'),
};

Done;
