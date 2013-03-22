package Provision::DSL::Local::Config;
use Moo;
use Hash::Merge 'merge';
use Provision::DSL::Const;

with 'Provision::DSL::Role::Local';

has name           => (is => 'ro');
has provision_file => (is => 'ro');
has resources      => (is => 'ro');
has local          => (is => 'ro');
has remote         => (is => 'ro');

sub default_config {
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
              # PERL_CPANM_OPT          => "--mirror http://localhost:${\HTTP_PORT} --mirror-only",
            },
        },

        resources => [],
    };
}

sub BUILDARGS {
    my ($class, %args) = @_;
    
    my $provision = $args{provision};
    
    my $config_from_file = $provision->has_config_file
        ? do "${\$provision->config_file}"
        : {};
    
    die 'Your config file does not look valid. It must return a Hash-Ref'
        if ref $config_from_file ne 'HASH';

    my $config = merge $config_from_file, default_config;

    push @{$config->{local}->{ssh_options}},
        '-R', "$config->{local}->{cpan_http_port}:127.0.0.1:$config->{remote}->{environment}->{PROVISION_HTTP_PORT}",
        '-R', "$config->{local}->{rsync_port}:127.0.0.1:$config->{remote}->{environment}->{PROVISION_RSYNC_PORT}";

    foreach my $arg (@{$provision->args}) {
        if (-f $arg) {
            $provision->provision_file($arg);
        } elsif ($arg =~ m{\A (.*) @ (.+) \z}xms) {
            $provision->hostname($2);
            $provision->user($1) if $1;
        }
    }

    # manually merge in some things entered via commandline
    $config->{remote}->{hostname} = $provision->hostname       if $provision->has_hostname;
    $config->{remote}->{user}     = $provision->user           if $provision->has_user;
    $config->{provision_file}     = $provision->provision_file if $provision->has_provision_file;
    $config->{name}             ||= $config->{provision_file} &&
                                    $config->{provision_file} =~ m{(\w+) [.] \w+ \z}xms
                                        ? $1
                                        : 'default';
    $config->{name}              =~ s{\W+}{_}xmsg;
    $config->{provision_file}   ||= 'provision.pl';

    $provision->log_debug($class, 'BUILDARGS:', $config);
    
    return $config;
}

1;
