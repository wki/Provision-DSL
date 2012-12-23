package Provision::DSL::Entity;
use Moo;
use Module::Load;
use Scalar::Util 'blessed';
use Try::Tiny;
use Provision::DSL::App;
use Provision::DSL::Types;
use Provision::DSL::Inspector::Never;

extends 'Provision::DSL::Base';
with 'Provision::DSL::Role::App',
     'Provision::DSL::Role::User';

# if we are a child:
has parent => (
    is        => 'ro',
    predicate => 1,
);

# children
has children => (
    is => 'lazy',
);

sub _build_children { [] }

sub add_child       { goto \&add_children }
sub add_children    { push @{ $_[0]->children }, @_[1..$#_] }

sub nr_children     { scalar @{ $_[0]->children } }

sub all_children    { @{ $_[0]->children } }

sub has_no_child    { goto \&has_no_children }
sub has_no_children { !scalar @{ $_[0]->children } }

# state management
has state => (
    is => 'lazy',
    clearer => 1,
);

sub _build_state {
    my $self = shift;
    
    ### FIXME: can we return 'N/A' as a state when the following things fail?

    $self->_clear_state; # clears _state (!)

    $self->add_to_state($self->inspect);
    $self->add_to_state($self->inspector_instance->state) # may fail
        if $self->has_inspector;

    $self->add_to_state( $_->is_ok ? 'current' : 'outdated' )
        for $self->all_children;

    $self->_state( $self->default_state ) if !$self->_has_state;

    return $self->_state;
}

has _state => (
    is        => 'rw',
    isa       => State,
    predicate => 1,
    clearer   => 1,
);

has default_state => (
    is => 'lazy',
);

sub _build_default_state { 'current' }

sub add_to_state {
    my $self  = shift;
    my $state = shift or return;

    if ( !$self->_has_state ) {
        $self->_state($state);
    }
    elsif ( $self->_state ne 'missing' && $self->_state ne $state ) {
        $self->_state('outdated');
        ### TODO: force children to become outdated also?
        $_->add_to_state('outdated') for $self->all_children;
    }
}

# privilege aggregation - overload accessor if needed.
has need_privilege => (
    is => 'lazy',
    isa => Bool,
);

sub _build_need_privilege {
    my $self = shift;

    my $need_privilege = 0;

    $need_privilege ||= $self->inspector_instance->need_privilege
        if $self->has_inspector;

    $need_privilege ||= $_->need_privilege
        for $self->all_children;

    ### TODO: if user/group given but different from current

    return $need_privilege;
}

# inspector and args -- set attribute or overload accessor to change
# [ inspector_package [, \%extra_args] [, @expected_values] ]
# typical usage: [ inspector_package, @expected_values ]
#
has inspector => (
    is        => 'ro',
    predicate => 1,
);

has inspector_instance => (
    is => 'lazy',
);

sub _build_inspector_instance {
    my $self = shift;

    return if !$self->has_inspector;

    my ($class, @args) = @{$self->inspector};
    
    my %args;
    %args = %{+shift @args} if ref $args[0] eq 'HASH';
    $args{expected_value} = \@args;
    
    return $class->new(entity => $self, %args);
}

# must get overloaded if we are inspecting ourselves
sub inspect {}

# installer and args -- set attribute or overload accessor to change
has installer => (
    is        => 'ro',
    predicate => 1,
);

has installer_instance => (
    is => 'lazy',
);

sub _build_installer_instance {
    my $self = shift;

    return if !$self->has_installer;

    my ($class, $args) = @{$self->installer};
    return $class->new(entity => $self, %{$args || {}});
}

### FIXME: use the same signature for installer/inspector
has _source => (
    is        => 'ro',
    predicate => 'has_source',
    init_arg  => 'source',
    # isa     =>  [ $class, @args ]
);

has source => (
    is => 'lazy',
    init_arg => undef,
);

sub _build_source {
    my $self = shift;
    
    die 'cannot build instance without source'
        if !$self->has_source;
    
    # may occur in child classes
    return $self->_source if blessed $self->_source;
    
    my ($class, @args) = @{ $self->_source };
    return $class->new(@args);
}

# must get overloaded if we are handling ourselves
sub create {}
sub change {}
sub remove {}

# installation
has wanted => (
    is      => 'ro',
    isa     => Str,
    default => sub { 1 }
);

sub install {
    my $self   = shift;
    my $wanted = shift; 
    my $state  = shift; 
    
    $wanted = $self->wanted if !defined $wanted;
    try {
        $state  = $self->state  if !defined $state;
    };
    
    my @log = ( $self, $state || 'N/A' );
    unshift @log, ' -' if $self->parent;

    if ( $state && $self->is_ok( $wanted, $state ) ) {
        $self->log( @log, '- OK' );
        return;
    }

    my $action = $wanted
        ? ( $state 
            ? $state eq 'missing' ? 'create' : 'change'
            : 'probably stop' )
        : 'remove';

    $self->log_dryrun( @log, "- would $action" ) and return;
    if (!$state) {
        $self->log( @log, 'unknown state, stopping');
        die 'cannot execute on unknown state';
    }

    $self->log( @log, "=> $action" );

    ### FIXME: is this wise? would it be better to let only one
    ###        action run? Either installer *OR* self
    
    if (!$wanted) { $_->install(0) for reverse $self->all_children }
    $self->$action();
    $self->installer_instance->$action() if $self->has_installer;
    if ($wanted) { $_->install for $self->all_children }

    $self->clear_state;
}

sub is_ok {
    my $self   = shift;
    my $wanted = shift; $wanted = $self->wanted if !defined $wanted;
    my $state  = shift; $state  = $self->state  if !defined $state;

    return
         ($state eq 'current' &&  $wanted)
      || ($state eq 'missing' && !$wanted);
}

1;
