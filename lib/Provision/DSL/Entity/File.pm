package Provision::DSL::Entity::File;
use Moo;
# use Carp;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity::Base::File';

sub _build_permission { '0644' }

has content => (
    is        => 'ro',
    isa       => Str,
    coerce    => to_Content,
    predicate => 1,
);

has patches => (
    is        => 'ro',
    predicate => 1,
);
 
sub inspect { -f $_[0]->path ? 'current' : 'missing' }

sub create {
    my $self = shift;
    
    $self->prepare_for_creation;
    
    $self->run_command_maybe_privileged(
        '/usr/bin/touch',
        $self->path,
    );
    
}

# before create => sub { $_[0]->_create_from_content };
# 
# sub _create_from_content {
#     my $self = shift;
# 
#     croak "File(${\$self->name}) no content for missing file"
#         if !$self->has_content;
# 
#     my $fh = $self->path->openw;
#     print $fh $self->content;
#     $fh->close;
# }

sub _build_children {
    my $self = shift;

    return [
        (
            $self->has_content
            ? $self->create_entity(
                File_Content => {
                    parent  => $self,
                    name    => $self->name,
                    path    => $self->path,
                    content => $self->content,
                }
              )
            : ()
        ),
        (
            $self->has_patches
            ? $self->create_entity(
                File_Patch => {
                    parent  => $self,
                    name    => $self->name,
                    path    => $self->path,
                    patches => $self->patches,
                }
              )
            : ()
        ),
        
        ### TODO: Privilege
        ### TODO: Owner
    ];
}

1;
