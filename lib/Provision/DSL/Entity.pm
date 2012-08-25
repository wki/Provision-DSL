package Provision::DSL::Entity;
use Moo;
use Module::Load;
use Try::Tiny;
use Provision::DSL::App;
use Provision::DSL::Types;
use vars '$AUTOLOAD';

extends 'Provision::DSL::Base';

sub AUTOLOAD {
    my $self = shift;
    
    my $sub_name = $AUTOLOAD;
    $sub_name =~ s{\A .* ::}{}xms;
    return if $sub_name =~ m{\A [A-Z]+ \z}xms;
    
    use feature ':5.10';
    my $package = "${\ref $self}::$sub_name";
    say "trying to call $package(${\join(', ', @_)})";
    
    try {
        load $package;
        # TODO: add as child
    } catch {
        say "could not load Module '$package'";
    };
}

has app => (
    is       => 'lazy',
    handles  => [
        qw(
            verbose dryrun
            log log_dryrun log_debug
            create_entity
            user_has_privilege
            run_command pipe_into_command command_succeeds
        )
    ],
);

sub _build_app { Provision::DSL::App->instance }

has parent  => ( is => 'ro',                    predicate => 1 );
has wanted  => ( is => 'ro',    isa => Str,     default => sub { 1 } );
has changed => ( is => 'rw',    isa => Bool,    default => sub { 0 } );
has _state  => ( is => 'rw',    isa => State,   predicate => 1, clearer => 1 );

has need_privilege  => ( is => 'lazy', isa => Bool);
sub _build_need_privilege { 0 }

has default_state   => ( is => 'lazy' );
sub _build_default_state { 'current' }

sub install {
    my $self   = shift;
    my $wanted = shift // $self->wanted;
    my $state  = shift // $self->state;

    my @log = ($self, $state);

    if ($self->is_ok($wanted, $state)) {
        $self->log(@log, '- OK');
        return;
    }

    $self->changed(1);

    my $action = $wanted
        ? ($state eq 'missing' ? 'create' : 'change')
        : 'remove';

    $self->log_dryrun(@log, "would $action") and return;
    $self->log(@log, "$state => $action");

    $self->$action();
    
    $self->_clear_state;
}

sub add_to_state {
    my $self  = shift;
    my $state = shift or return;
    
    if (!$self->_has_state) {
        $self->_state($state);
    } elsif ($self->_state ne 'missing' && $self->_state ne $state) {
        $self->_state('outdated');
    }
}

sub calculate_state {
    my $self = shift;
    
    # child classes and roles already ran their before methods if we are here
    ### TODO: call state_from->... hooks also
    
    $self->_state($self->default_state) if !$self->_has_state;
}

sub state {
    my $self = shift;
    
    $self->calculate_state if !$self->_has_state;

    return $self->_state;
}

sub is_ok {
    my $self   = shift;
    my $wanted = shift // $self->wanted;
    my $state  = shift // $self->state;

    return ($state eq 'current' &&  $wanted)
        || ($state eq 'missing' && !$wanted);
}

# 'before' and 'after' modifiers should get used for overloading
#    see t/1-calling_order_moo.t to understand which and why
sub create { }
sub change { }
sub remove { }

1;
