Provision-DSL
=============

a simple provisioning toolkit allowing to deploy and configure a remote
machine in a simple way.

having a config file like:

    {
        name => 'box',
        
        provision_file => 'box.pl',
        
        remote => {
            hostname => 'box',
        },
        
        resources => [
            {
                # copy everything inside xxx/resources except /dirx
                #    to 'resources/files'
                source      => 'xxx/resources',
                destination => 'files',
                exclude     => 'dirx',
            },
        ],
    }

and a provision file like:

    #!/usr/bin/env perl
    use Provision::DSL;
    my $WEB_DIR     = '/web/data';
    my $SITE_DIR    = "$WEB_DIR/www.mysite.de";
    
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

the destination machine will receive the setup from the provision file
