package Provision::DSL::Role::CheckDirExistence;
use Moo::Role;

around is_present => sub {
    my ($orig, $self) = @_;

    return -d $self->path && $self->$orig();
};

after create => sub { $_[0]->path->mkpath };

after change => sub { $_[0]->path->mkpath };

after remove => sub {
    my $self = shift;

    $self->path->traverse(\&_remove_recursive) if -d $self->path;
};

sub _remove_recursive {
    my ($child, $cont) = @_;
    
    warn "remove recursive: $child";
    $cont->() if -d $child;
    $child->remove;
}

1;
