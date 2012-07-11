package ParentRole1;
use Moo::Role;

around method => sub {
    my ($orig, $self) = @_;
    
    $self->show('before PR1::m');
    $self->$orig();
    $self->show('after PR1::m');
};

# before method => sub { $_[0]->show('before PR1::m') };
# after  method => sub { $_[0]->show('after PR1::m') };

1;
