package Provision::DSL::Execution;
use Moose;
use Provision::DSL::Execution::Step;
use namespace::autoclean;

has steps => (
    is => 'ro',
    isa => 'ArrayRef',
    default => sub { [] },
    required => 1,
);

sub add_step {
    my ($self, $entity) = @_;
    
    push @{$self->steps},
        Provision::DSL::Execution::Step->new(
            entity => $entity,
            priority => scalar @{$self->steps},
        );
}

# loop thru all steps and find 'tell' / 'listen' things
#   --> might die if non-existing names are used
sub calculate_execution_order {
    my $self = shift;
    
    # A tell B      ==> B reloads after A has changed
    # A listen B    ==> A reloads after B has changed
}

sub execute {
    my $self = shift;
    
    $_->execute
        for sort { $a->sort_key cmp $b->sort_key }
            @{$self->steps};
}

__PACKAGE__->meta->make_immutable;
1;
