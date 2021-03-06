package Provision::DSL::Entity::Base::File;
use Moo;
use Try::Tiny;
use Provision::DSL::Const;
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
    
    my $content;
    try {
        $content = $self->read_content_of_file($self->path);
    };
    
    return $content;
}

sub write_content {
    my ($self, $new_content) = @_;
    
    $self->run_command_maybe_privileged(
        TEE,
        { stdin => \$new_content },
        $self->path,
    );
}

1;
