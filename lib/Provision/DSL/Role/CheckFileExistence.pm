package Provision::DSL::Role::CheckFileExistence;
use Moo::Role;

around is_present => sub {
    my ($orig, $self) = @_;
    
    return -f $self->path && $self->$orig();
};

after remove => sub { $_[0]->path->remove };

1;
