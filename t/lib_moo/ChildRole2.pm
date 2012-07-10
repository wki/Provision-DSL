package ChildRole2;
use Moo::Role;

before method => sub { $_[0]->show('before CR2::m') };
after  method => sub { $_[0]->show('after CR2::m') };

1;
