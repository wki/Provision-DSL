package Provision::DSL::App;
use feature ':5.10';
use Moo;
use Carp;
use Scalar::Util 'blessed';
use Role::Tiny ();
use Try::Tiny;
use Provision::DSL::Types;
use Provision::DSL::Const;
use Provision::DSL::Util ();

with 'Provision::DSL::Role::CommandlineOptions',
     'Provision::DSL::Role::CommandExecution';

has is_running => (
    is => 'rw',
    default => sub { 0 },
);

has os => (
    is => 'ro',
    default => \&Provision::DSL::Util::os
);

has user_has_privilege => (
    is => 'lazy',
    isa => Bool,
    clearer => 1,
);

sub _build_user_has_privilege {
    my $self = shift;

    # be safe: kill the user's password timeout
    $self->run_command(SUDO, '-K');

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

####################################### Installation

sub add_entity_for_install {
    my ($self, $entity) = @_;

    push @{$self->entities_to_install}, $entity;
}

sub install_needs_privilege {
    my $self = shift;

    grep { $_->need_privilege } @{$self->entities_to_install};
}

sub requested_privilege_present {
    my $self = shift;

    return !$self->install_needs_privilege || $self->user_has_privilege;
}

sub install_all_entities {
    my $self = shift;

    croak 'nothing to install' unless @{$self->entities_to_install};

    $self->check_or_enable_privileges;

    $self->is_running(1);
    $_->install for @{$self->entities_to_install};
}

sub check_or_enable_privileges {
    my $self = shift;

    return if $self->requested_privilege_present;

    $self->log_dryrun('would prompt for "/etc/sudoers" expansion to gain permission')
        and return;

    my $user = getpwuid($<);
    say STDERR "WARNING: privilege needed to run this script.";
    say STDERR "         an entry like '$user ALL=NOPASSWD: ALL' can get added to /etc/sudoers.";
    say STDERR "         enter password if wanted, abort otherwise.";
    say STDERR "";

    # using system() here because of different stdin/stdout/stderr handling...
    system SUDO, '-S',
        '/bin/sh', '-c', "/bin/echo '$user ALL=NOPASSWD: ALL' >> /etc/sudoers";

    $self->clear_user_has_privilege;

    croak 'Privileged user needed for installing but `sudo -n` not working'
        if !$self->requested_privilege_present;
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
