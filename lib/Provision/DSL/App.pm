package Provision::DSL::App;
use Moo;
use Carp;
use Scalar::Util 'blessed';
use Module::Pluggable search_path => 'Provision::DSL::TraitFor',
                      sub_name => 'traits';
use Role::Tiny ();
use Try::Tiny;
use Provision::DSL::Types;

with 'Provision::DSL::Role::CommandlineOptions',
     'Provision::DSL::Role::CommandExecution';

# Entity => Provision::DSL::Entity::Xxx
has entity_package_for => (
    is => 'rw',
    default => sub { {} },
);

# Entity => { name => $object }
has _entity_cache => (
    is => 'rw',
    default => sub { {} },
);

has _channel_changed => (
    is => 'rw',
    default => sub { {} },
);

has _trait_package => (
    is => 'lazy',
);

sub _build_trait_package { { map { ($_ => 1) } $_->traits } }

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

    # die "create entity: $entity";

    my $class = $self->entity_package_for->{$entity}
        or croak "no class for entity '$entity' found";

    ### FIXME: does "re-create" error make sense?
    croak "cannot re-create entity '$entity' ($args->{name})"
        if exists $self->_entity_cache->{$entity}
           && exists $self->_entity_cache->{$entity}->{$args->{name}};

    my $instance = $class->new({ app => $self, %$args });
    my $name = $instance->name;

    my $os = $self->os;
    my @unknown_attributes;

    foreach my $attribute (keys %$args) {
        next if $instance->can($attribute);
        push @unknown_attributes, $attribute;

        my $class = ucfirst lc $attribute;
        $class =~ s{_}{\u}xmsg;

        foreach my $trait ("$entity\::$os\::$attribute", "$entity\::$attribute",
                           "$os\::$attribute",           $attribute)
        {
            my $package = "Provision::DSL::TraitFor::$trait";
            next if !exists $self->_trait_package->{$package};

            $self->log_debug("Applying Trait '$package' for attribute '$attribute'");

            Role::Tiny->apply_roles_to_object($instance, $package);
            last;
        }
    }

    foreach my $attribute (@unknown_attributes) {
        $instance->$attribute($args->{$attribute})
            if $instance->can($attribute);
    }

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

####################################### Channel Handling

sub set_changed {
    my ($self, $channel) = @_;

    $self->_channel_changed->{$channel} = 1;
}

sub has_changed {
    my ($self, $channel) = @_;

    return exists $self->_channel_changed->{$channel};
}

1;
