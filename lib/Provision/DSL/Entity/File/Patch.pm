package Provision::DSL::Entity::File::Patch;
use Moo;
use Carp;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity::Base::File';

has patches => (
    is      => 'ro',
    default => sub { [] }
);

sub inspect {
    my $self = shift;

    return !defined $self->current_content
        ? 'missing'
    : $self->current_content ne $self->apply_modification
        ? 'outdated'
        : 'current';
}

sub create { goto \&change }
sub change {
    my $self = shift;

    $self->write_content($self->apply_modification);
}

sub apply_modification {
    my ($self) = @_;

    my $content = $self->current_content;
    $content = '' if !defined $content;

    my $i = 1;
    foreach my $patch (@{$self->patches}) {
        my ($method) = grep { $self->can($_) } map { "patch_$_" } keys %$patch
            or do {
                carp "ignoring File(${$self->name}) patch #$i";
                next;
            };

        $content = $self->$method($patch, $content);

        $i++;
    }

    return $content;
}

####################################### various patches ### TODO: make classes?

sub patch_if_line_like {
    my ($self, $patch, $content) = @_;

    my $match = $patch->{if_line_like};

    my $nr_replacements =
        $content =~ s{^ ($match) $}{$self->_replace_with($patch)}exmsg;

    croak "File(${\$self->name}) patch '$match' is ambiguous"
        if $nr_replacements > 1;

    return $content;
}

sub _replace_with {
    my ($self, $patch) = @_;

    my $replacement = $patch->{replace_with}
        or croak "File(${\$self->name}) no replacement in patch '$patch->{if_line_like}'";

    my $original_line = $1;
    my $new_line = ref $replacement eq 'CODE'
        ? $replacement->()
        : $replacement;

    my $prefix = '';
    if ($original_line ne $new_line) {
        my $comment_symbol = $patch->{comment_symbol} || '#';
        my $time = scalar localtime time;

        $prefix .= "$comment_symbol MODIFIED BY Provision::DSL at $time\n";
        $prefix .= "$comment_symbol BEFORE: $original_line\n";
    }

    return $prefix . $new_line;
}

sub patch_append_if_missing {
    my ($self, $patch, $content) = @_;
    
    ### FIXME: here we rely on having a Resource(...).
    my $append_if_missing = $patch->{append_if_missing}->content;
    
    my $check_expression = $append_if_missing;
    $check_expression =~ s{(\S+)}{\\\\Q$1\\\\E}xmsg;
    $check_expression =~ s{\s+}{\\\\s*}xmsg;
    
    if ($content !~ m{$check_expression}xms) {
        $content =~ s{\s*\z}{"\n$append_if_missing"}exms;
    }
    
    return $content;
}

1;
