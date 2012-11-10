package Provision::DSL::Entity::_Ubuntu::Backup;
use Moo;
use Provision::DSL::Types;
use Provision::DSL::Const;

extends 'Provision::DSL::Entity::Backup';
with    'Provision::DSL::Role::CommandExecution';

sub create { goto \&change }
sub change {
    my $self = shift;
    
    $self->clean_old_backups;
    
    # this version is 3-4 times faster on linux than the generic version
    $self->run_command_as_user(
        CP,
        '--archive',   # do not deref links, recursive
        '--link',      # hard-link files instead of copying
        $self->source_dir => $self->backup_dir
    );
}

1;
