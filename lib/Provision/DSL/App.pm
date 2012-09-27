package Provision::DSL::App;
use feature ':5.10';
use Moo;
use Carp;
use Scalar::Util 'blessed';
use Role::Tiny ();
use Try::Tiny;
use Provision::DSL::Types;

with 'Provision::DSL::Role::CommandlineOptions',
     'Provision::DSL::Role::CommandExecution';

has is_running => (
    is => 'rw',
    default => sub { 0 },
);

has user_has_privilege => (
    is => 'lazy',
    isa => Bool,
);

sub _build_user_has_privilege {
    my $self = shift;

    # be safe: kill the user's password timeout
    $self->run_command('/usr/bin/sudo', '-K');

    my $result;
    try {
        $self->run_command_as_superuser($self->find_command('true'));
        $result = 1;
    # } catch {
    #     warn "Caught: $_";
    };
    
    return $result;
}

has entities_to_install => (
    is => 'rw',
    default => sub { [] },
);

# Xxx => Provision::DSL::Entity::Xxx
has entity_package_for => (
    is => 'rw',
    default => sub { {} },
);

# Entity => { name => $object }
has _entity_cache => (
    is => 'rw',
    default => sub { {} },
);

####################################### Singleton

around new => sub {
    my ($orig, $class, @args) = @_;
    
    ### is it clean to check for instance() in call hierarchy?
    for (my $i = 0; $i < 10; $i++) {
        my ($package, $filename, $line, $sub) = caller($i);
        
        next if !$sub || $sub !~ m{:: instance \z}xms;

        return $class->$orig(@args);
    }
    
    die 'Singleton-App: calling new directly is forbidden';
};

sub instance {
    my $class = shift;
    state $self = $class->new_with_options(@_);
    
    return $self;
}

sub DEMOLISH {
    my $self = shift;

    $self->log_debug('End of Program');
}

# maybe construct an attribute ???
sub os {
    my $self = shift;

    my $os = ref $self;
    $os =~ s{\A .* App::}{}xms
        or return 'Unknown';

    return $os;
}

####################################### Installation

sub add_entity_for_install {
    my ($self, $entity) = @_;

    push @{$self->entities_to_install}, $entity;
}

sub install_needs_privilege {
    my $self = shift;

    foreach my $entity (@{$self->entities_to_install}) {
        return 1 if $entity->need_privilege;
    }

    return 0;
}

sub install_all_entities {
    my $self = shift;

    $self->is_running(1);

    croak 'nothing to install'
        unless @{$self->entities_to_install};

    croak 'Privileged user needed for installing'
        if $self->install_needs_privilege && !$self->user_has_privilege;

    $_->install for @{$self->entities_to_install};
}

####################################### Entity handling

sub get_or_create_entity {
    my ($self, $entity, $name) = @_;

    my $instance;
    try {
        $instance = $self->get_cached_entity($entity, $name);
    } catch {
        $instance = $self->create_entity($entity, { name => $name });
    };

    return $instance;
}

sub create_entity {
    my ($self, $entity, $args) = @_;

    my $class = $self->entity_package_for->{$entity}
        or croak "no class for entity '$entity' found";

    croak "cannot re-create entity '$entity' ($args->{name})"
        if exists $self->_entity_cache->{$entity}
           && exists $self->_entity_cache->{$entity}->{$args->{name}};

    my $instance = $class->new({ app => $self, %$args });
    my $name = $instance->name;

    $self->log_debug("create_entity $entity($name) from", $args);
    return $self->_entity_cache->{$entity}->{$name} = $instance;
}

sub get_cached_entity {
    my $self = shift;
    my $entity = shift;
    my $name = shift;  # optional if only 1 entity exists

    croak "no entity '$entity' cached"
        if !exists $self->_entity_cache->{$entity};

    my $cache = $self->_entity_cache->{$entity};
    if ($name) {
        croak "entity '$entity' named '$name' not found"
            if !exists $cache->{$name};
        return $cache->{$name};
    } elsif (scalar keys %$cache == 1) {
        return (values %$cache)[0];
    } else {
        croak "entity '$entity' is ambiguous, name required";
    }
}

1;
