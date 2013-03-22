package Provision::DSL::Script::Provision;
use Moo;
use Cwd;
use Config;
use Path::Class;
use Provision::DSL::Script::Config;
use Provision::DSL::Script::Cache;
use Provision::DSL::Script::DSL;
use Provision::DSL::Script::RsyncDaemon;
use Provision::DSL::Script::Remote;
use Provision::DSL::Script::Timer;
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

has cache_dir => (
    is     => 'lazy',
    coerce => to_ExistingDir,
);

sub _build_cache_dir {
    my $self = shift;

    my $cache_dir_name = join '_', '.provision', $self->config->name || ();
    my $dir = $self->root_dir->subdir($cache_dir_name);
    $dir->mkpath if !-d $dir;
    
    return $dir;
}

# aggregations with lazy build
has config_file => ( is => 'ro', predicate => 1 );
has config => ( is => 'lazy' );
sub _build_config {
    my $self = shift;
    
    Provision::DSL::Script::Config->new(
        provision => $self,
    );
}

has cache => ( is => 'lazy' );
sub _build_cache {
    my $self = shift;
    
    Provision::DSL::Script::Cache->new(
        provision => $self,
        dir       => $self->cache_dir,
    );
}

has dsl => ( is => 'lazy' );
sub _build_dsl {
    my $self = shift;
    
    Provision::DSL::Script::DSL->new(
        provision => $self,
    );
}

has remote => ( is => 'lazy' );
sub _build_remote {
    my $self = shift;
    
    Provision::DSL::Script::Remote->new(
        provision => $self,
    );
}

has rsync_daemon => ( is => 'lazy' );
sub _build_rsync_daemon {
    my $self = shift;
    
    Provision::DSL::Script::RsyncDaemon->new(
        provision => $self,
    );
}

has timer => (
    is => 'ro',
    default => sub { Provision::DSL::Script::Timer->new(provision => $_[0]) },
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
    );
};

sub usage_text { '[[user]@hostname] [provision_file.pl] [(+|-|=) task]' }

sub run {
    my $self = shift;

    $self->cache->populate;
    $self->dsl->must_have_valid_syntax;

    $self->rsync_daemon->start;
        $self->remote->pull_cache;
        $self->remote->run_dsl;
        $self->remote->push_logs;
    $self->rsync_daemon->stop;
    
    $self->log(sprintf 'Elapsed: %0.1fs', $self->timer->elapsed);
}

1;
