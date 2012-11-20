package Provision::DSL::Role::ProcessControl::Ubuntu;
use Moo::Role;
use Path::Class;

sub _proc_file { file('/proc', $_[0]->pid || ()) }

sub is_running {
    my $self = shift;
    
    # warn "is_running. PID=" . $self->pid . 
    #     ', proc-file=' . $self->_proc_file . 
    #     ', -e: ' . (-e $self->_proc_file ? 'YES' : 'NO');
    
    $self->pid && -e $self->_proc_file;
}

sub started {
    my $self = shift;
    
    return if !$self->is_running;
    
    return $self->_proc_file->stat->mtime;
}

1;
