package Child;
use Moo;
use namespace::autoclean;

extends 'ParentX';
with 'ChildRole1','ChildRole2';

before method => sub { $_[0]->show('before C::m') };
after  method => sub { $_[0]->show('after C::m') };

# if method is implemented in child, 
# no methods (not even modifiers) from the parent are called
sub method { $_[0]->show('in C::m') }

1;
