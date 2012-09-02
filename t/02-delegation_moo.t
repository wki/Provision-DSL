use strict;
use warnings;
use Test::More;

# delegated class
{
    package D;
    use Moo;
    
    sub method {
        my $self = shift;
        my $text = shift // '';

        return $text . 'D::m';
    }
}

# main class
{
    package M;
    use Moo;
    
    has d => (
        is => 'ro',
        handles => ['method'],
    );
    
    around method => sub {
        my $orig = shift;
        my $self = shift;
        my $text = shift // '';
        
        return 'before/' . $self->$orig($text) . '/after';
    };
}

my $m = M->new(d => D->new);

is $m->method(), 'before/D::m/after', 'delegation can get modified';

done_testing;
