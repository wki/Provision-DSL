package Provision::DSL::Role::Content;
use Moo::Role;
use Scalar::Util 'blessed';

# defining content must be done careful because accessing ->content() may die
# and this must get defered as long as possible.
has _content => (
    is        => 'ro',
    predicate => 'has_content',
    init_arg  => 'content',
);

sub content {
    my $self = shift;
    
    my $content = $self->_content;
    
    return
        blessed $content && $content->can('content')
            ? $content->content
        : ref $content eq 'Path::Class::File'
            ? scalar $content->slurp
        : "$content";
}

1;
