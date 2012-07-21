{
    name           => 'sample config',
    provision_file => 'examples.pl',

    # only hostname is mandatory, all others are optional
    # options are added to the ssh commandline as-is
    ssh => {
        hostname      => 'localhost',
        user          => 'wolfgang',
        identity_file => 'id_rsa',
        # options     => '--foo 42 --bar zzz',
    },
    
    resources => [
        {
            # copy everything inside t/resources 
            #    to xxx inside resources directory in tar file
            source      => 't/resources',       # root directory
            destination => 'files',             # subdir inside resources
            exclude     => 'dirx',              # globs allowed
        },
        
        # ... more rules
    ],
}
