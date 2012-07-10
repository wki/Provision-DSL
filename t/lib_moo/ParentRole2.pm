package ParentRole2;
use Moo::Role;

before method => sub { $_[0]->show('before PR2::m') };
after  method => sub { $_[0]->show('after PR2::m') };

1;
