package Provision::DSL::Entity;
use Moo;
use Module::Load;
use Scalar::Util 'blessed';
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

# state management
has _state => (
    is        => 'rw',
    isa       => State,
    predicate => 1,
    clearer   => 1,
);

has default_state => ( is => 'lazy' );

sub _build_default_state { 'current' }

sub add_to_state {
    my $self = shift;
    my $state = shift or return;

    if ( !$self->_has_state ) {
        $self->_state($state);
    }
    elsif ( $self->_state ne 'missing' && $self->_state ne $state ) {
        $self->_state('outdated');
    }
}

sub calculate_state {
    my $self = shift;

    $self->inspect;

    $self->add_to_state( $_->is_ok ? 'current' : 'outdated' )
        for $self->all_children;

    $self->_state( $self->default_state ) if !$self->_has_state;
}

sub state {
    my $self = shift;

    $self->calculate_state if !$self->_has_state;

    return $self->_state;
}

# called from Inspector::Self. Override if all-in-one class wanted
sub self_calculate_state { 'current' }

# privilege aggregation
has need_privilege => (
    is => 'lazy',
    isa => Bool,
);

sub _build_need_privilege {
    my $self = shift;

    my $need_privilege = $self->inspector_instance->need_privilege;
    $need_privilege ||= $_->need_privilege for $self->all_children;
    
    ### TODO: if user/group given but different from current

    return $need_privilege;
}

# called from Inspector::Self. Override if all-in-one class wanted
sub self_calculate_need_privilege { 0 }

# inspector
has inspector => (
    is     => 'lazy',
    coerce => to_ClassAndArgs('Provision::DSL::Inspector'),
);

sub _build_inspector { 'Never' }

has inspector_instance => (
    is => 'lazy',
    handles => [qw(inspect)],
);

sub _build_inspector_instance {
    my $self = shift;
    
    return $self->inspector if blessed $self->inspector;
    
    my ($class, $args) = @{$self->inspector};
    return $class->new(entity => $self, %$args);
}

# installer and args
has installer => (
    is      => 'lazy',
    coerce  => to_ClassAndArgs('Provision::DSL::Installer'),
);

sub _build_installer { 'Null' }

has installer_instance => (
    is => 'lazy',
    handles => [qw(create change remove)],
);

sub _build_installer_instance {
    my $self = shift;
    
    return $self->installer if blessed $self->installer;
    
    my ($class, $args) = @{$self->installer};
    return $class->new(entity => $self, %$args);
}

# called from Installer::Self
sub self_create {}
sub self_change {}
sub self_remove {}

# children
has children => (
    is => 'lazy',
);

sub _build_children { [] }

sub add_child { push @{ $_[0]->children }, @_[1..$#_] }

sub nr_children { scalar @{ $_[0]->children } }

sub all_children { @{ $_[0]->children } }

sub has_no_children { !scalar @{ $_[0]->children } }

# installation
has wanted => (
    is      => 'ro',
    isa     => Str,
    default => sub { 1 }
);

sub install {
    my $self   = shift;
    my $wanted = shift // $self->wanted;
    my $state  = shift // $self->state;

    my @log = ( $self, $state );

    if ( $self->is_ok( $wanted, $state ) ) {
        $self->log( @log, '- OK' );
        return;
    }

    my $action = $wanted
        ? ( $state eq 'missing' ? 'create' : 'change' )
        : 'remove';

    $self->log_dryrun( @log, "would $action" ) and return;
    $self->log( @log, "$state => $action" );

    $self->$action();

    $self->_clear_state;
}

sub is_ok {
    my $self   = shift;
    my $wanted = shift // $self->wanted;
    my $state  = shift // $self->state;

    return
         ( $state eq 'current' &&  $wanted )
      || ( $state eq 'missing' && !$wanted );
}

after [ 'create', 'change' ] => sub { $_->install() for $_[0]->all_children };

before remove => sub { $_->install(0) for reverse $_[0]->all_children };

1;
