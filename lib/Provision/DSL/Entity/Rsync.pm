package Provision::DSL::Entity::Rsync;
use Moo;
use Provision::DSL::Types;
use Provision::DSL::Const;

extends 'Provision::DSL::Entity::Base::Dir';

has content => (
    is       => 'ro',
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
        
        if ($result && $result !~ m{^copying}xms && $result =~ m{^deleting}xms) {
            #
            # rsync behaves strange. If we have "abc/def" in exclude list,
            #     "abc/" is reported to get deleted.
            # to resolve this, we remove all lines like 'deleting xxx/'
            # for every parent dir of all excluded things.
            # this is only needed if we only have 'deleting...' lines
            #
            # warn "MUST CHECK DELETE LINES ($result)";
            
            foreach my $path (@{$self->exclude}) {
                $path =~ s{\A / | / \z}{}xmsg;
                my @parts = split qr{/+}, $path;
            
                # warn "checking ro remove $path";
                $result =~ s{^deleting \s+ $_ /? $}{}xms
                    for map { join '/', @parts[0..$_] } 
                        0 .. $#parts;
            }
            
            # warn "REMOVED LINES, TEST NOW: ($result)";
        }
        
        $self->add_info_line($_)
            for map { s{\A copying}{copy}xms; s{\A deleting}{delete}xms; $_ }
                grep { m{\A (copying|deleting) }xms }
                split qr{[\r\n]+}xms, $result;

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
        '--perms',
        '--delete',
        @_,
        $self->_exclude_list,
        "${\$self->content}/" => "${\$self->path}/",
    );
    
    my $result = $self->run_command_maybe_privileged(
        RSYNC, 
        @args
    );

    return $result;
}

sub _exclude_list {
    my $self = shift;

    my @exclude_list;
    foreach my $path (@{$self->exclude}) {
        $path =~ s{\A / | / \z}{}xmsg;
        my @parts = split qr{/+}, $path;
        
        #
        # must also exclude parent directories in order to avoid
        # reporting of deletions which would never occur
        # --exclude /foo/bar/baz leads to
        # --exlude /foo --exclude /foo/bar --exclude /foo/bar/baz
        #
        # WRONG: will also exclude deeded dirs from transmission.
        # push @exclude_list, '--exclude', join '/', '', @parts[0..$_]
        #     for 0 .. $#parts;
        push @exclude_list, '--exclude', join '/', '', @parts;
    }

    return @exclude_list;
}

1;
