package Provision::DSL::Entity::Dir;
use Moo;
use Try::Tiny;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity::Base::Dir';

sub BUILD {
    my $self = shift;
    
    $self->add_children(
        $self->__permission,
        $self->__owner,
        $self->__subdirs( $self->mkdir, 1 ),
        $self->__subdirs( $self->rmdir, 0 ),
        $self->__links,
        $self->__content,
    );
}

sub _build_permission { '0755' }

has mkdir => (
    is      => 'rw',
    default => sub { [] },
);

has rmdir => (
    is      => 'rw',
    default => sub { [] },
);

has links => (
    is      => 'rw',
    default => sub { {} },
);

has ignore => (
    is      => 'rw',
    default => sub { [] },
);

has content => (
    is        => 'ro',
    coerce   => to_RsyncSource,
    predicate => 1,
);

sub inspect { -d $_[0]->path ? 'current' : 'missing' }

# sub change {} not needed, changes done by children
# sub remove {} implemented in base class
sub create {
    my $self = shift;
    
    $self->prepare_for_creation;
    
    $self->run_command_maybe_privileged(
        $self->find_command('mkdir'),
        '-p', $self->path,
    );
}

sub __subdirs {
    my ( $self, $directories, $wanted ) = @_;

    map {
        $self->create_entity(
            Dir => {
                parent => $self,
                name   => $_,
                path   => $self->path->subdir($_),
                wanted => $wanted,
                ($self->has_user  ? (user  => $self->user)  : () ),
                ($self->has_group ? (group => $self->group) : () ),
            }
          )
      }
      @$directories;
}

sub __links {
    my $self = shift;
    
    return (
        map {
            $self->create_entity(
                Link => {
                    parent => $self,
                    name => $_,
                    path => $self->path->subdir($_),
                    link_to => $self->links->{$_},
                    ($self->has_user  ? (user  => $self->user)  : () ),
                    ($self->has_group ? (group => $self->group) : () ),
                }
            )
        }
        keys %{$self->links}
    );
}

sub __content {
    my $self = shift;
    
    return if !$self->has_content;
    
    return $self->create_entity(
        Rsync => {
            parent  => $self,
            name    => $self->name,
            path    => $self->path,
            content => $self->content,
            exclude => [ @{$self->mkdir}, keys %{$self->links}, @{$self->ignore} ],
        }
    );
}

1;
