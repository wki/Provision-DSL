package Provision::DSL::Source::Template;
use Moo;
use Template::Simple;

extends 'Provision::DSL::Source::Resource';

has vars => (
    is      => 'ro',
    default => sub { {} },
);

sub _build_content {
    my $self = shift;
    
    die 'a directory cannot act as a template' if -d $self->path;
    die 'template file does not exist' if !-f $self->path;
    
    my $renderer = Template::Simple->new(
        search_dirs => [ $self->path->dir ],
    );
    
    my $output = $renderer->render(scalar $self->path->slurp, $self->vars)
        or die "Error: ${\$renderer->error}";

    return $$output;
}

1;
