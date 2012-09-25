package Provision::DSL::Entity::File;
use Moo;
# use Carp;
use Provision::DSL::Types;

extends 'Provision::DSL::Entity::Base::File';

sub _build_permission { '0644' }

has content => (
    is        => 'ro',
    isa       => Str,
    coerce    => to_Content,
    predicate => 1,
);

has patch => (
    is        => 'ro',
    predicate => 1,
);
 
# sub BUILD {
#     my $self = shift;
# 
#     my $name = $self->name;
# 
#     croak "File($name) needs 'content' *OR* 'patches'"
#         if $self->_strict_args && !$self->has_content && !$self->has_patches;
# 
#     croak "File($name) can only have 'content' *OR* 'patches', not both"
#         if $self->has_content && $self->has_patches;
# }

sub inspect { -f $_[0]->path ? 'current' : 'missing' }

sub create {
    my $self = shift;
    
    $self->prepare_for_creation;
    
    $self->run_command_maybe_privileged(
        '/usr/bin/touch',
        $self->path,
    );
    
}

# before calculate_state => sub {
#     my $self = shift;
# 
#     if (!-f $self->path) {
#         $self->add_to_state('missing');
#     } else {
#         my $state = 'current';
#         my $current_content = scalar $self->path->slurp;
# 
#         $state = 'outdated'
#             if ($self->has_content
#                     && ($current_content ne $self->content))
#             || ($self->has_patches
#                     && ($current_content ne $self->apply_modification($current_content)));
# 
#         $self->add_to_state($state);
#     }
# };
# 
# sub apply_modification {
#     my ($self, $content) = @_;
# 
#     $content //= scalar $self->path->slurp;
# 
#     foreach my $patch (@{$self->patches}) {
#         my $match = $patch->{if_line_like}
#             or do {
#                 warn "Missing 'if_line_like' key, ignoring patch";
#                 next;
#             };
# 
#         my $nr_replacements =
#             $content =~ s{^ ($match) $}{$self->_replace($patch)}exmsg;
# 
#         croak "File(${\$self->name}) patch '$match' is ambiguous"
#             if $nr_replacements > 1;
#     }
# 
#     return $content;
# }
# 
# sub _replace_with {
#     my ($self, $patch) = @_;
# 
#     my $replacement = $patch->{replace_with}
#         or croak "File(${\$self->name}) no replacement in patch '$patch->{if_line_like}'";
# 
#     my $original_line = $1;
#     my $new_line = ref $replacement eq 'CODE'
#         ? $replacement->()
#         : $replacement;
# 
#     my $prefix = '';
#     if ($original_line ne $new_line) {
#         my $comment_symbol = $patch->{comment_symbol} // '#';
#         my $time = scalar localtime time;
# 
#         $prefix .= "$comment_symbol MODIFIED BY Provision::DSL at $time\n";
#         $prefix .= "$comment_symbol BEFORE: $original_line\n";
#     }
# 
#     return $prefix . $new_line;
# }
# 
# before create => sub { $_[0]->_create_from_content };
# 
# sub _create_from_content {
#     my $self = shift;
# 
#     croak "File(${\$self->name}) no content for missing file"
#         if !$self->has_content;
# 
#     my $fh = $self->path->openw;
#     print $fh $self->content;
#     $fh->close;
# }
# 
# before change => sub {
#     my $self = shift;
# 
#     if ($self->has_content) {
#         my $fh = $self->path->openw;
#         print $fh $self->content;
#         $fh->close;
#     } else {
#         my $fh = $self->path->openw;
#         print $fh $self->apply_modification;
#         $fh->close;
#     }
# };
# 
# after remove => sub { 
#     my $self = shift;
# 
#     $self->path->remove if $self->_allow_remove;
# };

sub _build_children {
    my $self = shift;

    return [
        ### TODO: Privilege
        ### TODO: Owner

        (
            $self->has_content
            ? $self->create_entity(
                FileContent => {
                    parent  => $self,
                    name    => $self->name,
                    path    => $self->path,
                    content => $self->content,
                }
              )
            : ()
        ),
        (
            $self->has_patch
            ? $self->create_entity(
                FilePatch => {
                    parent  => $self,
                    name    => $self->name,
                    path    => $self->path,
                    patch   => $self->patch,
                }
              )
            : ()
        ),
    ];
}

1;
