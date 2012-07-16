package Provision::DSL::Entity::Dir;
use Moo;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity::Compound';

sub path;    # must forward-declare
with 'Provision::DSL::Role::PathPermission',
     'Provision::DSL::Role::PathOwner';

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
    predicate => 'has_content',
);

sub is_present { -d $_[0]->path }

after ['create', 'change'] => sub { $_[0]->path->mkpath };

after remove => sub {
    my $self = shift;

    $self->path->traverse(\&_remove_recursive) if -d $self->path;
};

sub _remove_recursive {
    my ($child, $cont) = @_;

    $cont->() if -d $child;
    $child->remove;
}

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
