package Provision::DSL::Entity::_Ubuntu::Service::Rc;
use Moo;
use Path::Class;

extends 'Provision::DSL::Entity';
with    'Provision::DSL::Role::CommandExecution';

our $UPDATE_RCD = '/usr/sbin/update-rc.d';

sub _build_need_privilege { 1 }

sub inspect { 
    my $self = shift;
    
    my $etc_dir = dir('/etc');
    my $nr_files = 0;
    
    foreach my $rc_dir (map { $etc_dir->subdir("rc$_.d") } (0..6)) {
        $nr_files += 
            grep { $_->basename =~ m{\A [SK] \d+ ${\$self->name} \z}xms }
            $rc_dir->children;
    }
    
    return $nr_files ? 'current' : 'missing';
}

sub create { goto \&change }
sub change { 
    my $self = shift;
    
    $self->run_command_as_superuser(
        $UPDATE_RCD, $self->name, 'defaults'
    );
}

sub remove {
    my $self = shift;
    
    $self->run_command_as_superuser(
        $UPDATE_RCD, '-f', $self->name, 'defaults'
    );
}

1;
