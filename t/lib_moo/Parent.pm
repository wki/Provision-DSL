package Parent;
use Moo;

with 'ParentRole1';
with 'ParentRole2';

has message => (
    is => 'rw',
    default => sub { [] },
    # handles => {
    #     show => 'push',
    # },
);

sub show {
    my ($self, $text) = @_;
    
    push @{$self->message}, $text;
}

before method => sub { $_[0]->show('before P::m') };
after  method => sub { $_[0]->show('after P::m') };

sub method { $_[0]->show('in P::m') }

1;
