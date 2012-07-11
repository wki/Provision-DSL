package ParentRole2;
use Moo::Role;

around method => sub {
    my ($orig, $self) = @_;
    
    $self->show('before PR2::m');
    $self->$orig();
    $self->show('after PR2::m');
};

# before method => sub { $_[0]->show('before PR2::m') };
# after  method => sub { $_[0]->show('after PR2::m') };

1;
