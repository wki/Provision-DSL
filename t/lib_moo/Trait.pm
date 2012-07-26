package Trait;
use Moo::Role;

around method => sub {
    my ($orig, $self) = @_;
    
    $self->show('before T::m');
    $self->$orig();
    $self->show('after T::m');
};

before method => sub { $_[0]->show('b T::m') };
after  method => sub { $_[0]->show('a T::m') };

1;
