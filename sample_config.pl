{
    name => 'sample config',
    provision => 'xxx.pl',

    ssh => {
        user          => 'wolfgang',
        hostname      => 'localhost',
        identity_file => 'id_rsa_pass_wk',
    },
    
    resources => {
        include => [qw(abc def ghi)],
        exclude => 'ddd',
    },
}
