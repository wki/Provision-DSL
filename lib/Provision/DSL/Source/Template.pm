package Provision::DSL::Source::Template;
use Moo;
use Template::Simple;

extends 'Provision::DSL::Source::Resource';

has vars => (
    is => 'ro',
    default => sub { {} },
);

sub _build_content {
    my $self = shift;
    
    die 'a directory cannot act as a template' if -d $self->path;
    die 'template file does not exist' if !-f $self->path;
    
    my $output = '';
    my $renderer = Template->simple->new(
        search_dirs => [ $self->path->dir ],
    );
    
    $renderer->process($self->path->basename, $self->vars, \$output)
        or die "Error: ${\$renderer->error}";

    return $output;
}

1;
