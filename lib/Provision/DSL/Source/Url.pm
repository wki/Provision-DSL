package Provision::DSL::Source::Url;
use Moo;
use Try::Tiny;

extends 'Provision::DSL::Source';
with 'Provision::DSL::Role::HTTP';

has url => (
    is => 'lazy',
);

sub _build_url { $_[0]->name }

sub _build_content { 
    my $self = shift;
    
    my $content;
    try {
        $content = $self->http_get($self->url);
    } catch {
        die "Loading URL('${\$self->url}') failed: $_";
    };
    
    return $content;
}

1;
