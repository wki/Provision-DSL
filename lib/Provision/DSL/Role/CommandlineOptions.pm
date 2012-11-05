package Provision::DSL::Role::CommandlineOptions;
use Moo::Role;
use Getopt::Long 'GetOptionsFromArray';
use Scalar::Util 'blessed';
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

has log_dir => (
    is => 'rw',
    coerce => to_ExistingDir,
    predicate => 1,
);

has log_filename => (
    is => 'ro',
    default => sub { 'provision.log' },
);

has log_file => (
    is => 'lazy',
);

sub _build_log_file { $_[0]->log_dir->file($_[0]->log_filename) }

# expand in class/children/roles via 'around' modifier
sub options {
    return (
        'help|h      ; this help',
        'verbose|v   ; verbose mode - show messages',
        'dryrun|n    ; dryrun - do not install',
        'debug       ; show debug output',
    );
}

sub new_with_options {
    my $class = shift;
    my @argv = @_;

    my %opt;
    Getopt::Long::Configure('bundling');
    my $options_ok = GetOptionsFromArray(
        \@argv => \%opt,
        map {s{\s*;\s*.*}{}; $_} $class->options
    );

    $class->usage if $opt{help} || !$options_ok;

    return $class->new( { %opt, args => \@argv } );
}

sub usage {
    my $class = shift;

    my $app = $0;
    $app =~ s{\A .* /}{}xms;

    my $options = '';
    $options .= $class->usage_text if $class->can('usage_text');
    foreach my $option ($class->options) {
        ### FIXME: must get cleaned up a bit
        my ($name, $comment) = split qr{\s*;\s*}xms, $option;
        $name =~ s{[!+=:].*}{}xms;
        $name =~ s{\b(\w{2,})}{--$1};
        $name =~ s{\b(\w)\b}{-$1}xmsg;
        $name =~ s{\|}{ }xmsg;
        $options .= sprintf("\n  %-20s%s", $name, $comment || '');
    }
    $options .= "\n";

    print <<EOF;
$app [options] $options

EOF
    exit 1
}

sub log {
    my $self = shift;

    ### TODO: write to logfile (if defined) unless dryrun.
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

    if ($condition) {
        print join(' ', map { _to_string($_) } @_) . "\n";
        binmode(STDOUT);
    }

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
            ? ref($thing) .
              '<' . $thing->stringify . '>'
    :   "$thing"
}

1;
