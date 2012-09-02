package Provision::DSL::Entity;
use Moo;
use Provision::DSL::App;
use Provision::DSL::Types;
use Provision::DSL::Inspector::Never;

extends 'Provision::DSL::Base';
with 'Provision::DSL::Role::App';

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

    $self->inspector->inspect;

    $self->add_to_state( $_->is_ok ? 'current' : 'outdated' )
      for $self->all_children;

    $self->_state( $self->default_state ) if !$self->_has_state;
}

sub state {
    my $self = shift;

    $self->calculate_state if !$self->_has_state;

    return $self->_state;
}

# privilege aggregation
has need_privilege => ( is => 'lazy', isa => Bool );

sub _build_need_privilege {
    my $self = shift;

    my $need_privilege = $self->inspector->need_privilege;
    $need_privilege ||= $_->need_privilege for $self->all_children;

    return $need_privilege;
}

# inspector
has inspector_class => (
    is     => 'lazy',
    coerce => to_Class('Provision::DSL::Inspector')
);
sub _build_inspector_class { 'Always' }

has inspector_args => ( is => 'lazy' );
sub _build_inspector_args { +{} }

has inspector => ( is => 'lazy' );

sub _build_inspector {
    my $self = shift;

    my $class = $self->inspector_class;
    load $class;

    return $class->new( entity => $self, %{ $self->inspector_args } );
}

# installer
has installer_class => (
    is     => 'lazy',
    coerce => to_Class('Provision::DSL::Installer')
);

sub _build_installer_class { 'Null' }

around _build_installer_class => sub {
    my ( $orig, $self ) = @_;

    join '::', ( $self->need_privilege ? 'Privileged' : () ), $self->$orig();
};

has installer_args => ( is => 'lazy' );

sub _build_installer_args { +{} }

has installer => (
    is      => 'lazy',
    handles => [qw(create change remove)],
);

sub _build_installer {
    my $self = shift;

    my $class = $self->installer_class;
    load $class;

    return $class->new( entity => $self, %{ $self->installer_args } );
}

# children

has children => ( is => 'lazy' );

sub _build_children { [] }

sub add_child {
    my $self = shift;

    push @{ $self->children }, @_;
}

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

    my $action =
      $wanted
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

    return ( $state eq 'current' && $wanted )
      || ( $state eq 'missing' && !$wanted );
}

after [ 'create', 'change' ] => sub { $_->install() for $_[0]->all_children };

before remove => sub { $_->install(0) for reverse $_[0]->all_children };

1;
