package ParentRole1;
use Moo::Role;

before method => sub { $_[0]->show('before PR1::m') };
after  method => sub { $_[0]->show('after PR1::m') };

1;
