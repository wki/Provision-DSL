package Provision::DSL::Inspector::ProcessOlder;
use Moo;
use Path::Class;

extends 'Provision::DSL::Inspector::Base::Glob';

sub _build_attribute { 'started' }

sub filter {
    my ($class, $path) = @_;

    -f $path;
}

sub _build_state {
    my $self = shift;

    my $started = $self->value
        or return 'missing';

    foreach my $compare_file ($self->expected_values) {
        next if $compare_file->stat->mtime <= $started;

        return 'outdated';
    }

    return 'current';
}

1;
