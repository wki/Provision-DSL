package Provision::DSL::Source::Url;
use Moo;
use HTTP::Lite;

extends 'Provision::DSL::Source';

has url => (
    is => 'lazy',
);

sub _build_url { $_[0]->name }

sub _build_content {
    my $self = shift;
    
    my $http = HTTP::Lite->new;
    my $req = $http->request($self->url)
        or die "Unable to get '${\$self->url}': $!";
    return $http->body;
}

1;
