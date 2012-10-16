{
    # a name appended to the ".provision" directory name
    name => 'sample',
    
    # the file to run on the controlled machine
    provision_file => 'examples.pl',

    # ssh connection details
    #  - only hostname is mandatory, all others are optional
    #  - options are added to the ssh commandline as-is
    ssh => {
        hostname      => 'localhost',
        user          => 'wolfgang',
        identity_file => 'id_rsa',
        # options     => '--foo 42 --bar zzz',
    },
    
    # resources to get packed into resources/
    resources => [
        {
            # copy everything inside t/resources except /dirx
            #    to 'resources/files'
            source      => 't/resources',       # root directory
            destination => 'files',             # subdir inside resources
            exclude     => 'dirx',              # globs allowed
        },
        
        # ... more rules
    ],
    
    # optional definitions of paths on target machine
    path_for => {
        perl  => '/usr/bin/perl',
        rsync => '/usr/bin/rsync',
    },
    
    # maybe define some ports
    port_for => {
        cpan  => '2080:127.0.0.1:2080',
        rsync => '2873:127.0.0.1:2873',
    },
    
    # environment variables to set on the local machine
    environment => {
        (-d "$ENV{HOME}/minicpan"
            ? (PERL_CPANM_OPT => "--mirror $ENV{HOME}/minicpan --mirror-only")
            : ()),
    },
}
