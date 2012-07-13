package Provision::DSL::Role::CheckFileContent;
use Moo::Role;
use autodie ':all';

around is_current => sub {
    my ($orig, $self) = @_;
    
    return scalar $self->path->slurp eq $self->content && $self->$orig();
};

after ['create', 'change'] => sub {
    my $self = shift;
    
    my $fh = $self->path->openw;
    print $fh $self->content;
    $fh->close;
};

1;
