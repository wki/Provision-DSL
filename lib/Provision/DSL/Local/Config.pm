package Provision::DSL::Local::Config;
use Moo;
use Carp;
use Hash::Merge 'merge';
# use Try::Tiny;
use Provision::DSL::Const;

with 'Provision::DSL::Role::Local';

has file => (
    is        => 'ro',
    predicate => 1,
);

has _file_content => (
    is => 'lazy',
);

sub _build__file_content {
    my $self = shift;
    
    return {} if !$self->has_file;

    croak "could not open config file '${\$self->file}' -- file not found"
        if !-f $self->file;
    
    my $content = do "${\$self->file}";
    if (!defined $content) {
        $content = {};
        die "Could not read config file '${\$self->file}'";
    }
    
    return $content;
}

has _defaults => (
    is => 'lazy',
);

sub _build__defaults {
    +{
      # name => 'some_name',
      # provision_file => 'relative/path/to/file.pl',

        local => {
            ssh             => SSH,
            ssh_options     => ['-C'],
            cpanm           => CPANM,
            cpanm_options   => [],
            rsync           => RSYNC,
            rsync_port      => RSYNC_PORT,
            rsync_modules   => {},
            cpan_http_port  => HTTP_PORT,
            environment     => {},
        },

        remote => {
          # hostname        => 'box',
          # user            => 'wolfgang',

          # maybe add some options transported to remote via
          #     -o option,option,...
          #
          # options => {
          #     modify_sudoers => 1, # append '$user ALL=(ALL) NOPASSWD: ALL'
          # },

            environment => {
                PROVISION_RSYNC         => RSYNC,
                PROVISION_RSYNC_PORT    => RSYNC_PORT,
                PROVISION_PERL          => PERL,
                PROVISION_HTTP_PORT     => HTTP_PORT,
                PROVISION_HTTP_HOST     => '127.0.0.1',
              # PERL_CPANM_OPT          => "--mirror http://localhost:${\HTTP_PORT} --mirror-only",
            },
        },

        resources => [],
    };
}

has _merged_config  => (
    is => 'lazy',
);

sub _build__merged_config {
    my $self = shift;
    
    my $config = merge $self->_file_content, $self->_defaults;
    
    push @{$config->{local}->{ssh_options}},
        '-R', "$config->{local}->{cpan_http_port}:$config->{remote}->{environment}->{PROVISION_HTTP_HOST}:$config->{remote}->{environment}->{PROVISION_HTTP_PORT}",
        '-R', "$config->{local}->{rsync_port}:127.0.0.1:$config->{remote}->{environment}->{PROVISION_RSYNC_PORT}";
    
    # manually merge in some things from ENV
    # PROVISION_REMOTE_   HOSTNAME | USER | ENV_*
    foreach my $env_varname (grep { m{\A PROVISION_REMOTE_}xms } keys %ENV) {
        my $key = $env_varname;
        $key =~ s{\A PROVISION_REMOTE_}{}xms;
        
        if (exists $config->{remote}->{lc $key}) {
            $config->{remote}->{lc $key} = $ENV{$env_varname};
        } elsif ($key =~ m{\A env_(.+)\z}ixms) {
            $config->{remote}->{environment}->{uc $1} = $ENV{$env_varname};
        }
    }
    
    # manually merge in some things entered via commandline
    $config->{remote}->{hostname} = $self->app->hostname       if $self->app->has_hostname;
    $config->{remote}->{user}     = $self->app->user           if $self->app->has_user;
    $config->{provision_file}     = $self->app->provision_file if $self->app->has_provision_file;
    $config->{name}             ||= $config->{provision_file} &&
                                    $config->{provision_file} =~ m{(\w+) [.] \w+ \z}xms
                                        ? $1
                                        : 'default';
    $config->{name}              =~ s{\W+}{_}xmsg;
    $config->{provision_file}   ||= 'provision.pl';
    
    $self->log_debug('merged config:', $config);
    
    return $config;
}

foreach my $attribute (qw(name provision_file resources local remote)) {
    has $attribute => (
        is => 'lazy',
        default => sub { $_[0]->_merged_config->{$attribute} }
    );
}

1;
