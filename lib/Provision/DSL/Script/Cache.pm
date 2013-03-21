package Provision::DSL::Script::Cache;
use Moo;

with 'Provision::DSL::Role::Provision';

# the "Cache" represents the .provision_xxxx directory inside root_dir

has dir => (
    is => 'ro',
    # isa => 'type',
    # coerce => 1,
    required => 1,
);

sub BUILD {
    my $self = shift;
    
    $self->log_debug('BUILD', ref $self);
    
    $_->mkpath for grep { !-d }
                   map { $self->dir->subdir($_) }
                   qw(bin lib log resources);
}

sub populate {
    my $self = shift;
    
    $self->log_debug(ref $self, 'populate');
    
    # TODO: fill me.
}

1;
