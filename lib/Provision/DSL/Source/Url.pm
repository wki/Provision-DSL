package Provision::DSL::Source::Url;
use Moo;

extends 'Provision::DSL::Source';
with 'Provision::DSL::Role::HTTP';

has url => (
    is => 'lazy',
);

sub _build_url { $_[0]->name }

sub _build_content { 
    my $self = shift;
    
    warn "loading URL: ${\$self->url}";
    return $self->http_get($self->url);
}

1;
