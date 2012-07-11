package ModifyingChild;
use Moo;

extends 'Parent';
with 'ChildRole1';
with 'ChildRole2';

# around method => sub {
#     my ($orig, $self) = @_;
#     
#     $self->show('before MC::m');
#     $self->$orig();
#     $self->show('after MC::m');
# };

before method => sub { $_[0]->show('before MC::m') };
after  method => sub { $_[0]->show('after MC::m') };

# method() is not implemented in child.
# this activates all method calls in parent and all roles

1;
