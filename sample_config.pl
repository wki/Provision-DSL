{
    name => 'sample config',
    provision => 'xxx.pl',

    ssh => {
        user => 'worker',
        host => 'testcomputer.mydomain.de',
        key  => 'id_rsa_pass_wk.pub',
    },
    
    resources => {
        include => [qw(abc def ghi)],
        exclude => 'ddd',
    },
}
