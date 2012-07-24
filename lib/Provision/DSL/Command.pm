package Provision::DSL::Command;
use Moo;
use Provision::DSL::Types;

has command => (
    is => 'ro',
    isa => ExecutableFile,
    required => 1,
    coerce => to_File,
);

has args => (
    is => 'ro',
    default => sub { [] },
);

has env => (
    is => 'ro',
    default => sub { {} },
);

has ['stdin', 'stdout', 'stderr'] => (
    is => 'ro',
    predicate => 1,
);

# use Role User?
has user => (
    is => 'ro',
    coerce => to_User
    predicate => 1,
);

# use Role Group?
has group => (
    is => 'ro',
    coerce => to_Group
    predicate => 1,
);

has _status => (
    is => 'rw',
    predicate => '_has_status',
);

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    my %args;
    $args{command} = shift if !ref $_[0] && (scalar @_ == 1 || ref $_[1] eq 'HASH');
    %args = (%args, ref $_[0] eq 'HASH' ? %{$_[0]} : @_);

    return $class->$orig(%args);
};

sub run {
    
    ### sudo -n when user|group
}

sub status {
    my $self = shift;
    
    return $self->_has_status
        ? $self->_status
        : -1;
}

sub success {
    my $self = shift;
    
    return $self->status == 0;
}

=head1 Provision::DSL::Command

Provision::DSL::Command - Easy commandline execution

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHOR

Wolfgang Kinkeldei

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;
1;
