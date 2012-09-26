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

    return $self->current_content ne $self->apply_modification
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

    foreach my $patch (@{$self->patches}) {
        my $match = $patch->{if_line_like}
            or do {
                warn "Missing 'if_line_like' key, ignoring patch";
                next;
            };

        my $nr_replacements =
            $content =~ s{^ ($match) $}{$self->_replace_with($patch)}exmsg;

        croak "File(${\$self->name}) patch '$match' is ambiguous"
            if $nr_replacements > 1;
    }

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
        my $comment_symbol = $patch->{comment_symbol} // '#';
        my $time = scalar localtime time;

        $prefix .= "$comment_symbol MODIFIED BY Provision::DSL at $time\n";
        $prefix .= "$comment_symbol BEFORE: $original_line\n";
    }

    return $prefix . $new_line;
}

1;
