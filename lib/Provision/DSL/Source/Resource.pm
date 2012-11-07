package Provision::DSL::Source::Resource;
use Moo;
use FindBin;
use Provision::DSL::Types;
use Provision::DSL::Const;

extends 'Provision::DSL::Source';
with 'Provision::DSL::Role::CommandExecution';

has root_dir => (
    is     => 'lazy',
    isa    => ExistingDir,
    coerce => to_ExistingDir,
);

sub _build_root_dir { "$FindBin::Bin/resources" }


# Caution: accessing path issues rsync transfer
# path inside root_dir (Path::Class::File|Dir)
has path => (
    is => 'lazy',
);

sub _build_path {
    my $self = shift;

    my $thing = $self->root_dir->subdir($self->name)->cleanup;
    if (!-d $thing) {
        $thing = $self->root_dir->file($self->name)->cleanup;
        die "Resource-path does not exist: '${\$self->name}'"
            if !-f $thing;
    }

    return $thing->resolve;
}

sub _build_content {
    my $self = shift;

    die 'dir-resources cannot retrieve content' if -d $self->path;
    die 'file-resource does not exist'          if !-f $self->path;

    return scalar $self->path->slurp;
}

1;
