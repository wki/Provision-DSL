package Provision::DSL::Source::Resource;
use Moo;
use FindBin;
use Carp;
use Provision::DSL::Types;

extends 'Provision::DSL::Source';

has root_dir => (
    is     => 'lazy',
    isa    => ExistingDir,
    coerce => to_ExistingDir,
);

sub _build_root_dir { "$FindBin::Bin/resources" }

has path => (
    is => 'lazy',
);

sub _build_path {
    my $self = shift;

    my $thing = $self->root_dir->subdir($self->name);
    if (!-d $thing) {
        $thing = $self->root_dir->file($self->name);
        croak "Resource-path does not exist: '${\$self->name}'"
            if !-f $thing;
    }

    return $thing->resolve;
}

sub _build_content {
    my $self = shift;

    croak 'dir-resources cannot retrieve content' if -d $self->path;
    croak 'file-resource does not exist'          if !-f $self->path;

    return scalar $self->path->slurp;
}

1;
