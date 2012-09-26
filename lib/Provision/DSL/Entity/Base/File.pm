package Provision::DSL::Entity::Base::File;
use Moo;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity::Base::Path';

has path => (
    is     => 'lazy',
    coerce => to_File,
);

sub _build_path { $_[0]->name }

has current_content => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_current_content { 
    my $self = shift;
    
    $self->run_command_maybe_privileged('/bin/cat', $self->path);
}

sub write_content {
    my ($self, $new_content) = @_;
    
    $self->run_command_maybe_privileged(
        '/usr/bin/tee',
        { stdin => \$new_content },
        $self->path,
    );
}

1;
