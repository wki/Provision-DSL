package Provision::DSL::Role::HTTP;
use Moo::Role;
use HTTP::Tiny;
use Carp;

sub http_get {
    my ($self, $url) = @_;
    
    my $http = HTTP::Tiny->new;
    my $response = $http->get($url);
    
    # use Data::Dumper;
    # warn Data::Dumper->Dump([$response], ['response']) if !$response->{success};
    
    croak "Response failed: $response->{reason}" if !$response->{success};
    
    return $response->{content};
}

1;
