{
    # just a name, currently not used.
    name           => 'testing',
    
    # the file to run on the controlled machine
    provision_file => 't/conf/list_files.pl',

    local => {
        environment => {
            foo => 42,
            bar => 'some thing',
        },
        ssh_options => [ qw(--foo 42 --bar zzz) ],
    },
    
    # ssh connection details
    #  - only hostname is mandatory, all others are optional
    #  - options are added to the ssh commandline as-is
    remote => {
        hostname      => 'localhost',
        user          => 'nobody',
        
        environment => {
            XX42 => 'foo',
        },
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
    ],
}
