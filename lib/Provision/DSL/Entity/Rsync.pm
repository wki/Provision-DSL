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
            '--verbose',
            '--dry-run',
            '--out-format' => 'copying %n',
        );
        
        # warn "RESULT: $result";
        
        $state = ($result && $result =~ m{^(?:deleting|copying)\s}xms)
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
        '--checksum',
        '--recursive',
        '--delete',
        @_,
        $self->_exclude_list,
        "${\$self->content}/" => "${\$self->path}/",
    );
    
    # FIXME: do we need privileges?
    # warn "rsync @args...";
    return $self->run_command(
        '/usr/bin/rsync', 
        # {stdout => sub { warn @_ }},
        @args
    );
}

sub _exclude_list {
    my $self = shift;

    my @exclude_list;
    foreach my $path (@{$self->exclude}) {
        $path =~ s{\A / | / \z}{}xmsg;
        my @parts = split qr{/+}, $path;
        
        push @exclude_list, 
             '--exclude', join('/', '', @parts[0..$#parts]);
    }

    return @exclude_list;
}

1;
