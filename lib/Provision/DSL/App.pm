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

has is_running => (
    is      => 'rw',
    default => sub { 0 },
);

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

sub run {
    my $self = shift;

    $self->is_running(1);

    ### TODO: dispatch to the action required
    $self->install_all_entities;
}
####################################### Installation

sub add_entity {
    my ($self, $name, $args) = @_;
    
    push @{$self->entities_to_install}, { name => $name, args => $args };
}

# sub _requested_privilege_present {
#     my $self = shift;
# 
#     return $self->user_has_privilege
#         || !grep { $_->need_privilege } @{$self->entities_to_install};
# }

sub install_all_entities {
    my $self = shift;

    # croak 'Provileged user needed for provision'
    #     if !$self->_requested_privilege_present;

    if (!@{$self->entities_to_install}) {
        print STDERR "nothing to install, empty provision file\n";
    } else {
        my $user = ($self->has_log_user ? "[${\$self->log_user}]" : '');
        $self->log_to_file("<<< start of Provision $user");

        foreach my $entity_info (@{$self->entities_to_install}) {
            my $entity;
            try {
                $entity = $self->create_entity($entity_info->{name}, $entity_info->{args});
            } catch {
                my $name = join ':',
                    $entity_info->{name},
                    $entity_info->{args}->{name} // ();
                
                $entity = $self->create_entity(Error => { name => $name, args => $entity_info->{args} });
            };
            $entity->install;
        }

        $self->log_to_file(">>> end of Provision $user\n");
    }
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
