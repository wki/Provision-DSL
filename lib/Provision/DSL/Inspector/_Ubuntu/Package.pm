package Provision::DSL::Inspector::_Ubuntu::Package;
use Moo;
use Try::Tiny;

extends 'Provision::DSL::Inspector';
with 'Provision::DSL::Role::CommandExecution';

sub _build_state {
    my $self = shift;
    
    my $state = 'missing';
    try {
        my $result = $self->run_command(
            '/usr/bin/dpkg-query',
            '--show',
            '--showformat', '${Package}\\t${Version}\\t${Status}',
            $self->value,
        );
        
        my ($package, $version, $status) = split qr{\t}, $result;
        
        # FIXME: must compare with requested version
        $state = $status =~ m{installed}xms
            ? 'current'
            : 'outdated';
    };
    
    return $state;
}

1;

__END__

# simple query of a package:
dpkg-query --show --showformat '${Package}\t${Version}\t${Status}\n' curl
