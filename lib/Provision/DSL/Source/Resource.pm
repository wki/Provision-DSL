package Provision::DSL::Source::Resource;
use Moo;
use FindBin;
use Carp;
use Provision::DSL::Types;

extends 'Provision::DSL::Source';
with 'Provision::DSL::Role::CommandExecution';

has root_dir => (
    is     => 'lazy',
    isa    => ExistingDir,
    coerce => to_ExistingDir,
);

sub _build_root_dir { "$FindBin::Bin/resources" }

### FIXME: hard coded rsync URL
sub rsync_source { 'rsync://localhost:2873/resources/' . $_[0]->name }

# path inside root_dir (Path::Class::File)
has path => (
    is => 'lazy',
);

sub _build_path {
    my $self = shift;
    
    my $path = $self->root_dir->file($self->name)->cleanup;

    my $parent_dir = $path->dir;
    $parent_dir->mkpath if !-d $parent_dir;

    ### FIXME: hard coded rsync path
    run_command('/usr/bin/rsync', $self->rsync_source, $path)
        if !-f $path;
    
    return $path;

    # my $thing = $self->root_dir->subdir($self->name)->cleanup;
    # if (!-d $thing) {
    #     $thing = $self->root_dir->file($self->name)->cleanup;
    #     croak "Resource-path does not exist: '${\$self->name}'"
    #         if !-f $thing;
    # }

    # return $thing->resolve;
}

sub _build_content {
    my $self = shift;

    return scalar $self->path->slurp;
}

1;
