package Provision::DSL::Local::HttpDaemon;
use Moo;
use HTTP::Server::PSGI;
use Plack::App::File;
use Provision::DSL::Const;
use Provision::DSL::Types;

extends 'Provision::DSL::Local::Daemon';

sub _build_name { 'http' }

has dir => (
    is       => 'ro',
    required => 1,
);

has port => (
    is      => 'ro',
    default => sub { HTTP_PORT },
);

sub start_daemon {
    my $self = shift;

    my $app = Plack::App::File->new(root => $dir)->to_app;
    
    my $server = HTTP::Server::PSGI->new(
        host    => '127.0.0.1',
        port    => $self->port,
        timeout => 30,
    );
    
    $server->run($app);
}

1;
