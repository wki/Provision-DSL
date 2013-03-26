Provision-DSL
=============

a simple provisioning toolkit allowing to deploy and configure a remote
machine in a simple way without having to install things on the remote before.

having a config file like:

    {
        # a meaningful name appended to temporary filenames
        name => 'box',
        
        # execute this script on the remote machine
        provision_file => 'box.pl',
        
        # optional definitions for the local machine, eg. minicpan
        local => {
            environment => {
                PERL_CPANM_OPT => "--mirror $ENV{HOME}/minicpan --mirror-only"
            },
        },
        
        # specifications for the remote machine
        remote => {
            hostname => 'box',
        },
        
        # files needed for the provisioning process
        resources => [
            {
                # make everything in 'xxx/resources' except '/dirx'
                #    accessible via Resource('files') during provision
                source      => 'xxx/resources',
                destination => 'files',
                exclude     => 'dirx',
            },
        ],
    }

and a provision file like:

    #!/usr/bin/env perl
    
    use Provision::DSL;
    
    # define variables in another file in the same directory
    # with optional global variables
    include vars, IP => '1.2.3.4', host => 'example.com';
    
    Package 'build-essential';
    # ... more packages
    
    Perlbrew {
        wanted  => '5.16.0',
        install_cpanm => 1,
    };
    
    Dir $WEB_DIR => {
        user => 'root',
        permission => '0755',
    };
    
    Dir $SITE_DIR => {
        user => 'sites',
        content => Resource('website'),
        
        mkdir => [qw(
            logs
            pid
        )],
    };
    
    Done;

by firing the shell command:

    $ provision.pl -c path/to/config.conf

or:

    $ provision.pl -c path/to/config.conf user@host.tld -v

the destination machine will receive the setup from the provision file.
During the provisioning process every entity will check if itself already
is in the right state or leave itself in the desired state.
