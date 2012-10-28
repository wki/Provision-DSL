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
    
    # define variables in another file
    include vars;
    
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

the destination machine will receive the setup from the provision file.
During the provisioning process every entity will check if itself already
is in the right state or leave itself in the desired state.
