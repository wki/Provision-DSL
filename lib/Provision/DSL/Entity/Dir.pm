package Provision::DSL::Entity::Dir;
use Moo;
use Try::Tiny;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity';
with    'Provision::DSL::Role::CommandExecution';

sub _build_permission { '0755' }

has path => (
    is     => 'lazy',
    coerce => to_Dir,
);
sub _build_path { $_[0]->name }

has mkdir => (
    is      => 'rw',
    default => sub { [] },
);

has rmdir => (
    is      => 'rw',
    default => sub { [] },
);

has content => (
    is        => 'ro',
    coerce    => to_ExistingDir,
    predicate => 1,
);

sub _build_inspector_class { 'DirPresent' }

sub _build_installer_class { 'MkDir' }

sub _build_children {
    my $self = shift;

    return [
        $self->__as_entities( $self->mkdir, 1 ),
        $self->__as_entities( $self->rmdir, 0 ),

        (
            $self->has_content
            ? $self->create_entity(
                Rsync => {
                    parent  => $self,
                    name    => $self->name,
                    path    => $self->path,
                    content => $self->content,
                    exclude => $self->mkdir,
                }
              )
            : ()
        ),
    ];
}

sub __as_entities {
    my ( $self, $directories, $wanted ) = @_;

    map {
        $self->create_entity(
            Dir => {
                parent => $self,
                name   => $_,
                path   => $self->path->subdir($_),
                wanted => $wanted,
            }
          )
      }
      @$directories;
}

1;
