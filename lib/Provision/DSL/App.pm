package Provision::DSL::App;
use Moo;
use FindBin;
use Carp;
use Scalar::Util 'blessed';
use Role::Tiny ();
use Try::Tiny;
use Provision::DSL::Types;
use Provision::DSL::Const;
use Provision::DSL::Util ();

with 'Provision::DSL::Role::CommandlineOptions',
     'Provision::DSL::Role::CommandExecution',
     'Provision::DSL::Role::Singleton';

has os => (
    is      => 'ro',
    default => \&Provision::DSL::Util::os
);

has user_has_privilege => (
    is      => 'lazy',
    isa     => Bool,
);

sub _build_user_has_privilege {
    my $self = shift;

    # be safe: kill the user's password timeout
    $self->run_command(SUDO, '-K');

    my $result;
    try {
        $self->run_command_as_superuser(TRUE);
        $result = 1;
    };

    return $result;
}

# to be precise, only name/arg pairs are stored here
# as hashref: { name => $name, args => \%args }
has entities_to_install => (
    is => 'rw',
    default => sub { [] },
);

# Xxx => Provision::DSL::Entity::Xxx
has entity_package_for => (
    is      => 'rw',
    default => sub { {} },
);

# Entity => { name => $object }
has _entity_cache => (
    is      => 'rw',
    default => sub { {} },
);

sub DEMOLISH {
    my $self = shift;

    $self->log_debug('End of Program');
}

####################################### Installation

sub log_start {
    my $self = shift;
    
    $self->log_to_file('<<< start of Provision', $self->_get_log_user);
    
}

sub log_finish {
    my $self = shift;
    
    $self->log_to_file('>>> end of Provision', $self->_get_log_user, "\n");
}

sub _get_log_user {
    my $self = shift;

    return $self->has_log_user
        ? "[${\$self->log_user}]"
        : ();
}

sub install_entity {
    my ($self, $name, $args) = @_;
    
    my $entity;
    try {
        $entity = $self->create_entity($name, $args);
    } catch {
        my $error_name = join ':',
            $name,
            $args->{name} // ();
        
        $entity = $self->create_entity(Error => { name => $error_name, args => $args });
    };
    $entity->install;
}

# sub _requested_privilege_present {
#     my $self = shift;
# 
#     return $self->user_has_privilege
#         || !grep { $_->need_privilege } @{$self->entities_to_install};
# }

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

    # FIXME: 'name' might be absent here. eg Perlbrew
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
