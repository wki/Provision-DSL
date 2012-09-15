package Provision::DSL::Entity::Rsync;
use Moo;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity';

has path => (
    is     => 'lazy',
    coerce => to_Dir,
);
sub _build_path { $_[0]->name }

has content => (
    is       => 'ro',
    coerce   => to_ExistingDir,
    required => 1,
);

has exclude => (
    is      => 'ro',
  # coerce  => to_DirList, ### FIXME: create me
    default => sub { [] },
);

# act as inspector and installer myself
# Reason: _rsync command and other attributes needed
sub _build_inspector { 'Self' }
sub _build_installer { 'Self' }

sub self_determine_state {
    my $self = shift;
    
    my $state = 'missing';
    if (-d $self->path) {
        my $result = $self->_run_rsync_command(
            '--dry-run',
            '--out-format' => 'copying %n',
        );
        
        $state = $result =~ m{^(?:deleting|copying)\s}xms
        ? 'outdated'
        : 'current';
    }
    
    return $state;
}

sub self_create { $_[0]->_run_rsync_command }
sub self_change { $_[0]->_run_rsync_command }

sub _run_rsync_command {
    my $self = shift;

    my @args = (
        '--verbose',
        '--checksum',
        '--recursive',
        '--delete',
        @_,
        $self->_exclude_list,
        "${\$self->content}/" => "${\$self->path}/",
    );
    
    return $self->run_command('/usr/bin/rsync', @args);
}

# rsync reports to delete a directory if its subdirectory is in exclusion
# thus, we have to resolve every path to every of its parents
sub _exclude_list {
    my $self = shift;

    my @exclude_list;
    foreach my $path (@{$self->exclude}) {
        $path =~ s{\A / | / \z}{}xmsg;
        my @parts = split qr{/+}, $path;
        
        push @exclude_list, 
             '--exclude', join('/', '', @parts[0..$_],'')
            for (0..$#parts);
    }

    return @exclude_list;
}

1;
