package Provision::DSL::Inspector::LinkExists;
use Moo;

extends 'Provision::DSL::Inspector::Base::Glob';

sub filter {
    my ($class, $path) = @_;
    
    -l $path;
}

sub _build_state { 
    my $self = shift;
    
    foreach my $link ($self->expected_values) {
        return 'missing' if !-l $link;
    }
    
    return 'current';
}

1;
