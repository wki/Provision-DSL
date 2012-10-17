{
    name => 'box',
    
    # the file to run on the controlled machine
    provision_file => 'box.pl',

    # ssh connection details
    #  - only hostname is mandatory, all others are optional
    #  - options are added to the ssh commandline as-is
    ssh => {
        hostname      => 'box',
        # user          => 'wolfgang',
        # identity_file => 'id_rsa',
        # options     => '--foo 42 --bar zzz',
        
        # TODO: implement this
        environment => { foo => 42 },
    },
    
    # resources to get packed into resources/ in a tar archive
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
    
    # on my wishlist: install a cpan mirror for target machine
    cpan_mirror => {
        root => "$ENV{HOME}/minicpan",
        port => 8080,
    },
    
    # environment variables to set on the local machine
    # environment => {
    #     (-d "$ENV{HOME}/minicpan"
    #         ? (PERL_CPANM_OPT => "--mirror $ENV{HOME}/minicpan --mirror-only")
    #         : ()),
    # },
}
