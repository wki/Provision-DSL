package Provision::DSL::Entity;
use Moo;
use Provision::DSL::Types;

has name => ( is => 'ro', isa => Str, required => 1);

has app => (
    is       => 'ro',
    required => 1,
    handles  => [
        qw(verbose dryrun
          log log_dryrun log_debug
          create_entity
          system_command pipe_into_command command_succeeds
          set_changed has_changed)
    ],
);

has parent => ( is => 'ro', predicate => 'has_parent' );

has state => ( is => 'lazy', isa => Str, clearer => 'clear_state' );

has wanted  => ( is => 'ro', isa => Bool, default => sub { 1 } );
has changed => ( is => 'rw', isa => Bool, default => sub { 0 } );

has listen => ( is => 'ro', coerce => to_Channels, default => sub { [] } );
has talk   => ( is => 'ro', coerce => to_Channels, default => sub { [] } );

# these conditions have precedence over methods is_present, is_current
# testing order is as follows:
# for is_present: only_if, not_if,
# for is_current: update_if, keep_if
has only_if   => ( is => 'ro', isa => CodeRef, predicate => 'has_only_if' );
has not_if    => ( is => 'ro', isa => CodeRef, predicate => 'has_not_if' );
has update_if => ( is => 'ro', isa => CodeRef, predicate => 'has_update_if' );
has keep_if   => ( is => 'ro', isa => CodeRef, predicate => 'has_keep_if' );

sub _build_state {
    my $self = shift;

    return 'missing'  if !$self->is_present;
    return 'outdated' if !$self->is_current;
    return 'current';
}

sub _build_uid { $< }

sub _build_gid { $( }

sub is_ok {
    my $self = shift;
    my $wanted = shift // $self->wanted;

    return ( !$wanted && $self->state eq 'missing' )
      || ( $wanted && $self->state eq 'current' );
}

sub execute {
    my $self = shift;
    my $wanted = shift // $self->wanted;

    if ($self->is_ok($wanted)) {
        $self->log($self, 'OK');
        return;
    }

    $self->changed(1);

    $self->set_changed($_) for @{ $self->talk };

    if ( !$wanted ) {
        $self->log($self, "state: ${\$self->state}", 'remove');
        $self->remove();
    }
    elsif ( $self->state eq 'missing' ) {
        $self->log($self, "state: ${\$self->state}", 'create');
        $self->create();
    }
    else {
        $self->log($self, "state: ${\$self->state}", 'change');
        $self->change();
    }

    $self->clear_state;
}

sub is_present {
    my $self = shift;

    return
        $self->has_only_if ? !$self->only_if->()
      : $self->has_not_if  ? $self->not_if->()
      :                      1;
}

sub is_current {
    my $self = shift;

    return
        $self->has_update_if ? !$self->update_if->()
      : $self->has_keep_if   ? $self->keep_if->()
      : scalar @{ $self->listen } ? (grep { $self->has_changed($_) } @{ $self->listen })
      : 1;
}

# returns a coderef which when called forces change
sub reloader {
    my $self = shift;

    return sub {
        $self->state('outdated');
        $self->execute;
    };
}

#
# may be overloaded in first level child class
# should not get overloaded any further,
#    instead 'before' and 'after' modifiers should get used.
#    see t/0-calling_order.t to understand why
#
sub create { }
sub change { }
sub remove { }

1;
