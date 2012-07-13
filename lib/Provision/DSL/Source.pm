package Provision::DSL::Source;
use Moo;
use Provision::DSL::Types;

has name => (
    is => 'ro',
    isa => Str,
    required => 1,
);

has content => (
    is => 'lazy',
    isa => Str,
);

# builder must be created in child class if content wanted

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    
    my %args;
    $args{name} = shift if !ref $_[0];
    %args = (%args, ref $_[0] eq 'HASH' ? %{$_[0]} : @_);
    
    return $class->$orig(%args);
};

1;
