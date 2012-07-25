package Provision::DSL::Entity::File;
use Moo;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity';

sub path;       # must forward-declare
sub content;    # must forward-declare

with 'Provision::DSL::Role::PathPermission',
     'Provision::DSL::Role::PathOwner';

sub _build_permission { '0644' }

has path => (
    is => 'lazy',
    coerce => to_File,
);

sub _build_path { $_[0]->name }

has content => (
    is => 'ro',
    isa => Str,
    coerce => to_Str,
    predicate => 1,
);

has patches => {
    is => 'ro'
    predicate => 1,
};

sub BUILD {
    my $self = shift;

    my $name = $self->name;
    
    croak "File($name) needs 'content' *OR* 'patches'"
        if !$self->has_content && !$self->has_patches;

    croak "File($name) can only have 'content' *OR* 'patches', not both"
        if $self->has_content && $self->has_patches;
}

sub state {
    my $self = shift;

    return 'missing' if !-f $self->path;

    my $current_content = scalar $self->path->slurp;

    if ($self->has_content) {
        return $current_content eq $self->content
            ? 'current'
            : 'outdated';
    } else {
        my $modified_content = $self->apply_modification($current_content);
        return $current_content eq $modified_content
            ? 'current'
            : 'outdated';
    }
}

sub apply_modification {
    my ($self, $content) = @_;

    $content //= scalar $self->path->slurp;

    foreach my $patch (@{$self->patches}) {
        my $match = $patch->{if_line_like}
            or do {
                warn "Missing 'if_line_like' key, ignoring patch";
                next;
            };

        my $nr_replacements =
            $content =~ s{^ ($match) $}{_replace($patch)}exmsg;
        
        croak "File(${\$self->name}) patch '$match' is ambiguous"
            if $nr_replacements > 1;
    }

    return $content;
}

sub _replace_with {
    my $patch = shift;
    
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

before create => sub { $_[0]->_create_from_content };

sub _create_from_content {
    my $self = shift;
    
    croak "File(${\$self->name}) no content for missing file"
        if !$self->has_content;

    my $fh = $self->path->openw;
    print $fh $self->content;
    $fh->close;
}

before change => sub {
    my $self = shift;

    if ($self->has_content) {
        my $fh = $self->path->openw;
        print $fh $self->content;
        $fh->close;
    } else {
        my $fh = $self->path->openw;
        print $fh $self->apply_modification;
        $fh->close;
    }
};

after remove => sub { $_[0]->path->remove };

1;
