package ChildRole1;
use Moo::Role;

before method => sub { $_[0]->show('before CR1::m') };
after  method => sub { $_[0]->show('after CR1::m') };

1;
