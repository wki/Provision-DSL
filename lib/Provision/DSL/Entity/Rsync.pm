package Provision::DSL::Entity::Rsync;
use Moo;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity';

has path => (
    is => 'lazy',
    coerce => to_Dir,
);
sub _build_path { $_[0]->name }

has content => (
    is => 'ro',
    coerce => to_ExistingDir,
    required => 1,
);

has exclude => (
    is => 'ro',
    # coerce => to_DirList, ### FIXME: create me
    default => sub { [] },
);

before state => sub {
    my $self = shift;
    
    my $state = 'current';

    if (!-d $self->path) {
        $state = 'missing';
    } else {
        $state =
            $self->_rsync_command(
                    '--dry-run',
                    '--out-format' => 'copying %n',
            ) =~ m{^(?:deleting|copying)\s}xms
        ? 'outdated'
        : 'current';
    }
    
    $self->set_state($state);
};

sub _rsync_command {
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
    
    return $self->system_command('/usr/bin/rsync', @args);
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

after ['create', 'change'] => sub { $_[0]->_rsync_command };

1;
