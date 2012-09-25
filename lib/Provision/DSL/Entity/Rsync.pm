package Provision::DSL::Entity::Rsync;
use Moo;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity::Base::Dir';

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

sub inspect {
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

sub create { $_[0]->_run_rsync_command }
sub change { $_[0]->_run_rsync_command }

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
