package Provision::DSL::Base;
use Moo;
use Carp;
use Provision::DSL::Types;

has name => (
    is => 'lazy',
    isa => Str,
);

sub _build_name { croak '"name" attribute is mandatory' }

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    my %args;
    $args{name} = shift if !ref $_[0] && (scalar @_ == 1 || ref $_[1] eq 'HASH');
    %args = (%args, ref $_[0] eq 'HASH' ? %{$_[0]} : @_);

    return $class->$orig(%args);
};

sub BUILD {
    my $self = shift;
    
    # trigger builder to ensure we have a name or die
    my $dummy = $self->name;
}

1;
