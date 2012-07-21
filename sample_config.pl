{
    name => 'sample config',
    provision => 'xxx.pl',

    # only hostname is mandatory, all others are optional
    # options are added to the ssh commandline as-is
    ssh => {
        hostname      => 'localhost',
        user          => 'wolfgang',
        identity_file => 'id_rsa',
        # options     => '--foo 42 --bar zzz',
    },
    
    resources => {
        include => [qw(abc def ghi)],
        exclude => 'ddd',
    },
}
