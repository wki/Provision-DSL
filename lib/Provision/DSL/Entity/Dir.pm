package Provision::DSL::Entity::Dir;
use Moo;
use Try::Tiny;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity::Base::Dir';

sub _build_permission { '0755' }

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

sub inspect { -d $_[0]->path ? 'current' : 'missing' }

# sub change {} not needed
# sub remove {} in base class
sub create {
    my $self = shift;
    
    $self->prepare_for_creation;
    
    $self->run_command_maybe_privileged(
        '/bin/mkdir',
        '-p', $self->path,
    );
}

sub _build_children {
    my $self = shift;

    return [
        ### TODO: Privilege
        ### TODO: Owner
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
