package Provision::DSL::App;
use feature ':5.10';
use Moo;
use IPC::Open3 'open3';
use Try::Tiny;
use Carp;
use Scalar::Util 'blessed';
use Getopt::Long 'GetOptionsFromArray';
use Provision::DSL::Types;

has verbose => (
    is => 'ro',
    isa => Bool,
    default => sub { 0 },
);

has debug => (
    is => 'ro',
    isa => Bool,
    default => sub { 0 },
);

has dryrun => (
    is => 'ro',
    isa => Bool,
    default => sub { 0 },
);

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

####################################### Option processing

sub new_with_options {
    my $class = shift;
    my @argv = @_;

    my %options;
    Getopt::Long::Configure('bundling');
    GetOptionsFromArray(
        \@argv => \%options,

        'verbose|v',    'dryrun|n',
        'debug',        'help|h|?',
    );
    usage() if $options{help};

    return $class->new(\%options);
}

sub usage {
    say <<EOF;
$0 [options]

  --dryrun -n    just simulate
  --verbose -v   print progress messages
  --debug        print debug info

  --help         this help
EOF
    exit 1
}

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
        return (values $cache->{$name})[0];
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

####################################### logging

sub log {
    my $self = shift;
    
    $self->_log_if($self->verbose || $self->debug, @_);
}

sub log_debug {
    my $self = shift;
    
    $self->_log_if($self->debug, 'DEBUG:', @_);
}

sub log_dryrun {
    my $self = shift;
    
    $self->_log_if($self->dryrun, @_);
}

sub _log_if {
    my $self = shift;
    my $condition = shift;

    say STDERR join(' ', map { _to_string($_) } @_) if $condition;

    return $condition;
}

sub _to_string {
    my $thing = shift;

    return
        !defined $thing
            ? '(undef)'
    :   !ref $thing
            ? "$thing"
    :   ref $thing eq 'ARRAY'
            ? '[ ' .
              join(', ',
                   map { _to_string($_) } @$thing) .
              ' ]'
    :   ref $thing eq 'HASH'
            ? '{ ' .
              join(', ',
                   map { "$_: ". _to_string($thing->{$_})} keys %$thing) .
              ' }'
    :   ref($thing) =~ m{\A Provision::DSL::Entity \b .* :: ([^:]+) \z}xms
            ? "$1('${\$thing->name}')"
    :   blessed $thing && $thing->can('stringify')
            ? ref $thing . 
              '<' . $thing->stringify . '>'
    :   "$thing"
}

####################################### Command execution

sub command_succeeds {
    my $self = shift;
    my @args = @_;

    my $result;
    try {
        $self->pipe_into_command('', @args);
        $result = 1;
    };

    return $result;
}

sub system_command {
    my $self = shift;

    return $self->pipe_into_command('', @_);
}

sub pipe_into_command {
    my $self = shift;
    my $input_text = shift;
    my @system_args = @_;

    # warn 'execute:', join(' ', @system_args);
    $self->log_debug('execute:', @system_args);

    my $pid = open3(my $in, my $out, my $err, @system_args);
    print $in $input_text // ();
    close $in;

    my $text = join '', <$out>;
    waitpid $pid, 0;

    my $status = $? >> 8;
    croak "command '@system_args' failed. status: $status" if $status;

    return $text;
}

1;
