package ModifyingChild;
use Moo;

extends 'ParentX';
with 'ChildRole1','ChildRole2';

around method => sub {
    my ($orig, $self) = @_;
    
    $self->show('before MC::m');
    $self->$orig();
    $self->show('after MC::m');
};

before method => sub { $_[0]->show('b MC::m') };
after  method => sub { $_[0]->show('a MC::m') };

1;
