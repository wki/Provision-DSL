package Provision::DSL::Base;
use Moo;

has name => (
    is => 'ro',
    isa => Str,
    required => 1,
);

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    my %args;
    $args{name} = shift if !ref $_[0] && (scalar @_ == 1 || ref $_[1] eq 'HASH');
    %args = (%args, ref $_[0] eq 'HASH' ? %{$_[0]} : @_);

    return $class->$orig(%args);
};

1;
