package Provision::DSL::Entity;
use Moo;
use Carp;
use Provision::DSL::Types;

has name => ( is => 'lazy', isa => Str);
sub _build_name { croak '"name" attribute is mandatory' }

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

has wanted  => ( is => 'ro', isa => Str,  default => sub { 1 } );
has changed => ( is => 'rw', isa => Bool, default => sub { 0 } );

has listen => ( is => 'ro', coerce => to_Channels, default => sub { [] } );
has talk   => ( is => 'ro', coerce => to_Channels, default => sub { [] } );

# these conditions have precedence over is_ok
has only_if   => ( is => 'ro', isa => CodeRef, predicate => 'has_only_if' );
has not_if    => ( is => 'ro', isa => CodeRef, predicate => 'has_not_if' );

has default_state => ( is => 'lazy' );
sub _build_default_state { 'current' }

sub _build_uid { $< }
sub _build_gid { $( }

sub execute {
    my $self   = shift;
    my $wanted = shift // $self->wanted;
    my $state  = shift // $self->state;

    my @log = ($self, $state);
    
    if (my @changed = grep { $self->has_changed($_) } @{$self->listen}) {
        push @log, 'heard: ' . join(', ', @changed);
    } elsif ($self->is_ok($wanted, $state)) {
        $self->log(@log, '- OK');
        return;
    }

    $self->changed(1);
    $self->set_changed($_) for @{$self->talk};

    my $action = $wanted
        ? ($state eq 'missing' ? 'create' : 'change')
        : 'remove';

    $self->log_dryrun(@log, "would $action") and return;
    $self->log(@log, "$state => $action");

    $self->$action();
}

sub state { 
    my $self = shift;
    
    if (@_) {
        return 'missing' if $_[0] eq 'missing';
        my %seen = map { ($_ => 1) } @_;
        return 'outdated' if scalar keys %seen > 1;
        return (keys %seen)[0];
    } else {
        return $self->default_state;
    }
}

# # merge my own state with states of former called "around" states
# # others win if 'missing', otherwise 'outdated' is reported if different
# sub merge_state {
#     my ($self, $other_state, $my_state) = @_;
#     
#     return $other_state eq 'missing'
#         ? 'missing'
#     : $other_state eq $my_state
#         ? $my_state
#         : 'outdated';
# }

sub is_ok {
    my $self   = shift;
    my $wanted = shift // $self->wanted;
    my $state  = shift // $self->state;

    my $ok = ($wanted && $state eq 'current')
        ||  (!$wanted && $state eq 'missing');

    ### FIXME: does not look very clever yet.
    my $modifier =
        $self->has_only_if ? !$self->only_if->()
      : $self->has_not_if  ? $self->not_if->()
      :                      1;

    return $ok && $modifier;
}

# returns a coderef which when called forces change
sub reloader {
    my $self = shift;

    return sub { $self->execute };
}

# 'before' and 'after' modifiers should get used for overloading
#    see t/1-calling_order_moo.t to understand which and why
sub create { }
sub change { }
sub remove { }

1;
