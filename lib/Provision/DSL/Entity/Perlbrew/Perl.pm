package Provision::DSL::Entity::Perlbrew::Perl;
use Moo;
# use Provision::DSL::Util 'remove_recursive';
# 
extends 'Provision::DSL::Entity';
with    'Provision::DSL::Role::CommandExecution';

sub inspect { -f $_[0]->parent->perl ? 'current' : 'missing' }

sub create { goto \&change }
sub change {
    my $self = shift;
    
    $self->run_command_as_user(
        '/usr/bin/perl',
        $self->parent->perlbrew,
        'install' => $self->parent->install_perl,
    );
}

sub remove{
    my $self = shift;

    my $perl_dir =$self->parent->perl->dir->parent;
    
    warn "WOULD REMOVE: $perl_dir";
    # $perl_dir->traverse(\&remove_recursive)
    #     if -d $perl_dir;
}

1;
