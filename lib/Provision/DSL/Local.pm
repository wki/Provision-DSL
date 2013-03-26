package Provision::DSL::Local;
use Moo;
use Cwd;
use Config;
use Path::Class;
use Provision::DSL::Local::Config;
use Provision::DSL::Local::Cache;
use Provision::DSL::Local::RsyncDaemon;
use Provision::DSL::Local::Proxy;
use Provision::DSL::Local::Timer;
use Provision::DSL::Types;

with 'Provision::DSL::Role::CommandlineOptions',
     'Provision::DSL::Role::Singleton';

# basic attributes, configurable via commandline-options
# allow to override config
has hostname => (
    is        => 'rw',
    predicate => 1,
);

# allow to override config
has user => (
    is        => 'rw',
    predicate => 1,
);

# allow to override config
has provision_file => (
    is        => 'rw',
    predicate => 1,
);

# allow faking arch during tests
has archname => (
    is      => 'ro',
    default => sub { $Config{archname} },
);

# directories with lazy build
has root_dir => (
    is     => 'lazy',
    coerce => to_ExistingDir,
);

sub _build_root_dir {
    my $self = shift;

    my $dir = dir(getcwd);

    while (scalar $dir->dir_list > 1) {
        return $dir
            if -f $dir->file('Makefile.PL') || -f $dir->file('dist.ini');
        $dir = $dir->parent;
    }

    # FIXME: wouldn't it be better die die?
    return dir('/tmp');
}

# aggregations with lazy build
has config_file => ( is => 'rw', predicate => 1 );

has config => ( is => 'lazy' );

sub _build_config {
    my $self = shift;

    Provision::DSL::Local::Config->new(
        ($self->has_config_file ? (file => $self->config_file) : ()),
    ),
}

has cache_dir => (
    is     => 'lazy',
    coerce => to_ExistingDir,
);

sub _build_cache_dir {
    my $self = shift;

    my $remote = $self->config->remote;

    my $cache_dir_name =
        join '_', 
             '.provision', 
             $self->config->name || (),
             ($remote->{user} || '') . "\@$remote->{hostname}";
    my $dir = $self->root_dir->subdir($cache_dir_name);
    $dir->mkpath if !-d $dir;

    return $dir;
}

has cache => ( is => 'lazy' );

sub _build_cache {
    my $self = shift;

    Provision::DSL::Local::Cache->new(
        dir => $self->cache_dir,
    );
}

has proxy => ( is => 'lazy' );

sub _build_proxy { 
    my $self = shift;
    
    my $remote = $self->config->remote;
    my $local  = $self->config->local;
    
    Provision::DSL::Local::Proxy->new(
        host    => $remote->{hostname},
        options => {
            ($remote->{user} ? (user => $remote->{user}) : ()),
            master_opts => $local->{ssh_options},
        },
    );
}

has rsync_daemon => ( is => 'lazy' );

sub _build_rsync_daemon {
    my $self = shift;

    Provision::DSL::Local::RsyncDaemon->new(
        dir => $self->cache_dir,
    );
}

has timer => (
    is      => 'ro', # not lazy, must initialize at startup
    default => sub {
        Provision::DSL::Local::Timer->new
    },
);

has task => (
    is => 'ro',
);

around options => sub {
    my ($orig, $self) = @_;

    return (
        $self->$orig,
        'config_file|c=s    ; specify a config file',
        'root_dir|r=s       ; root dir for locating files and resources',
        'hostname|H=s       ; hostname for ssh, overrides config setting',
        'user|u=s           ; user for ssh, overrides config setting',
        'provision_file|p=s ; provision file to run, overrides config setting',
      # 'options|o=s        ; comma separated options [modify_sudoers, TODO:more]'
      # 'force|f            ; force every entity to execute',
      # 'status|s'          ; show a status for every task, implies dryrun
        'task|t=s@          ; specify (no-)tasks to +add, -ignore or =only run',
    );
};

sub usage_text { '[[user]@hostname] [provision_file.pl] [ -- (+-=)[no-]task]' }

sub BUILD {
    my $self = shift;
    
    foreach my $arg (@{$self->args}) {
        if (-f $arg) {
            $self->provision_file($arg);
        } elsif ($arg =~ m{\A (.*) @ (.+) \z}xms) {
            $self->hostname($2);
            $self->user($1) if $1;
        } else {
            warn "Extra Arg: '$arg'";
        }
        ### TODO: handle tasks
    }
}

sub run {
    my $self = shift;

    # use Data::Dumper; warn Dumper $self->task;
    # die 'stop for testing';

    $self->cache->populate;

    $self->rsync_daemon->start;
        $self->proxy->pull_cache;
        my $status = $self->proxy->run_dsl;
        $self->proxy->push_logs;
    $self->rsync_daemon->stop;

    $self->log(sprintf 'Elapsed: %0.1fs', $self->timer->elapsed);
    
    return $status;
}

1;
