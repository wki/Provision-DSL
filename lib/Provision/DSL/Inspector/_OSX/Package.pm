package Provision::DSL::Inspector::_OSX::Package;
use Moo;
use Try::Tiny;

extends 'Provision::DSL::Inspector';

sub _build_state {
    my $self = shift;
    
    my $state = 'missing';
    try {
        my $result = $self->run_command(
            '/opt/local/bin/port',
            'installed', 'active', 'and',
            $self->value,
        );
        
        $result =~ s{\A \s+ | \s+ \z}{}xmsg;
        my ($package, $version, $status) = split qr{\s+}, $result;
        
        # FIXME: must compare with requested version
        $state = $status =~ m{active}xms
            ? 'current'
            : 'outdated';
    };
    
    return $state;
}

1;
