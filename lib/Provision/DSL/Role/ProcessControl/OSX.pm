package Provision::DSL::Role::ProcessControl::OSX;
use Moo::Role;
use Try::Tiny;
use Path::Class;
use Provision::DSL::Const;
use POSIX 'mktime';

with 'Provision::DSL::Role::CommandExecution';

sub is_running { $_[0]->_get_ps_column('pid') }
sub started { _convert_to_epoch($_[0]->_get_ps_column('lstart')) }

sub _get_ps_column {
    my $self   = shift;
    my $column = shift // 'comm';
    
    return if !$self->pid;
    
    my $result;
    try {
        local $ENV{LC_ALL} = 'C'; # in case of date output
        $result = $self->run_command(
            PS,
            '-p', $self->pid,
            '-o', $column);
        
        # remove header line and trailing spaces
        $result =~ s{\A .+? \n | \s* \z}{}xmsg;
    };
    return $result;
}

our %month_for = (Jan => 0, Feb => 1, Mar => 2,
                  Apr => 3, May => 4, Jun => 5,
                  Jul => 6, Aug => 7, Sep => 8,
                  Oct => 9, Nov =>10, Dec =>11);

# format: 'Sat Oct 27 22:12:15 2012'
sub _convert_to_epoch {
    my $time = shift;
    
    return if $time !~ m{(\w+) \s+ (\d+) \s+ (\d+):(\d+):(\d+) \s+ (\d+)}xms;
    
    return mktime($5, $4, $3, $2, $month_for{$1}, $6-1900);
}

1;
