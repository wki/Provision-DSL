package Provision::DSL::Role::AppOptions;
use feature ':5.10';
use Moo::Role;
use Getopt::Long 'GetOptionsFromArray';
use Provision::DSL::Types;

has verbose => (
    is => 'ro',
    isa => Bool,
    default => sub { 0 },
);

has debug => (
    is => 'ro',
    isa => Bool,
    default => sub { 0 },
);

has dryrun => (
    is => 'ro',
    isa => Bool,
    default => sub { 0 },
);

has args => (
    is => 'ro',
    default => sub { [] },
);

sub new_with_options {
    my $class = shift;
    my @argv = @_;

    my %options;
    Getopt::Long::Configure('bundling');
    GetOptionsFromArray(
        \@argv => \%options,

        'verbose|v',    'dryrun|n',
        'debug',        'help|h|?',
        
        ($class->can('extra_options') 
            ? (map {s{;.*}{}; $_} $class->extra_options)
            : ()),
    );
    
    usage($class) if $options{help};

    return $class->new( { %options, args => \@argv } );
}

sub usage {
    my $class = shift;
    
    my $app = $0;
    $app =~ s{\A .* /}{}xms;

    my $extra = '';
    if ($class->can('extra_options')) {
        foreach my $option ($class->extra_options) {
            ### FIXME: must get cleaned up a bit
            my ($name, $comment) = split ';', $option;
            $name =~ s{=.*}{}xms;
            $name =~ s{\b(\w{2,})}{--$1};
            $name =~ s{\b(\w)\b}{-$1}xmsg;
            $name =~ s{\|}{ }xmsg;
            $extra .= sprintf("\n  %-20s%s", $name, $comment || '');
        }
        $extra .= "\n";
    }

    say <<EOF;
$app [options]

  --dryrun -n         just simulate
  --verbose -v        print progress messages
  --debug             print debug info

  --help              this help
$extra
EOF
    exit 1
}

sub log {
    my $self = shift;
    
    $self->_log_if($self->verbose || $self->debug, @_);
}

sub log_debug {
    my $self = shift;
    
    $self->_log_if($self->debug, 'DEBUG:', @_);
}

sub log_dryrun {
    my $self = shift;
    
    $self->_log_if($self->dryrun, @_);
}

sub _log_if {
    my $self = shift;
    my $condition = shift;

    say STDERR join(' ', map { _to_string($_) } @_) if $condition;

    return $condition;
}

sub _to_string {
    my $thing = shift;

    return
        !defined $thing
            ? '(undef)'
    :   !ref $thing
            ? "$thing"
    :   ref $thing eq 'ARRAY'
            ? '[ ' .
              join(', ',
                   map { _to_string($_) } @$thing) .
              ' ]'
    :   ref $thing eq 'HASH'
            ? '{ ' .
              join(', ',
                   map { "$_: ". _to_string($thing->{$_})} keys %$thing) .
              ' }'
    :   ref($thing) =~ m{\A Provision::DSL::Entity \b .* :: ([^:]+) \z}xms
            ? "$1('${\$thing->name}')"
    :   blessed $thing && $thing->can('stringify')
            ? ref $thing . 
              '<' . $thing->stringify . '>'
    :   "$thing"
}

1;
