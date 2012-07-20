package Provision::DSL::App;
use feature ':5.10';
use Moo;
use Carp;
use Scalar::Util 'blessed';
use Provision::DSL::Types;

with 'Provision::DSL::Role::CommandlineOptions',
     'Provision::DSL::Role::CommandExecution';

# Entity => Provision::DSL::Entity::Xxx
has entity_package_for => (
    is => 'rw',
    # isa => 'HashRef',
    default => sub { {} },
);

# Entity => { name => $object }
has _entity_cache => (
    is => 'rw',
    # isa => 'HashRef',
    default => sub { {} },
);

has _channel_changed => (
    is => 'rw',
    # isa => 'HashRef',
    default => sub { {} },
);

sub DEMOLISH {
    my $self = shift;

    $self->log_debug('End of Program');
}

####################################### Entity handling

sub create_entity {
    my $self   = shift;
    my $entity = shift;

    # die "create entity: $entity";

    my %args = (app => $self);
    $args{name} = shift if !ref $_[0];
    %args = (%args, ref $_[0] eq 'HASH' ? %{$_[0]} : @_);

    my $class = $self->entity_package_for->{$entity}
        or croak "no class for entity '$entity' found";

    ### FIXME: does "re-create" error make sense?
    croak "cannot re-create entity '$entity' ($args{name})"
        if exists $self->_entity_cache->{$entity}
           && exists $self->_entity_cache->{$entity}->{$args{name}};

    $self->log_debug("create_entity $entity($args{name}) from", \%args);
    return $self->_entity_cache->{$entity}->{$args{name}} = $class->new(\%args);
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
