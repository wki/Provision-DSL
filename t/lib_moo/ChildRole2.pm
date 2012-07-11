package ChildRole2;
use Moo::Role;

around method => sub {
    my ($orig, $self) = @_;
    
    $self->show('before CR2::m');
    $self->$orig();
    $self->show('after CR2::m');
};

# before method => sub { $_[0]->show('before CR1::m') };
# after  method => sub { $_[0]->show('after CR1::m') };

1;
