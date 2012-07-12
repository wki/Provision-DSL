package Provision::DSL::Types;
# use Path::Class;
use Carp;
use base 'Exporter';

our @EXPORT = qw(
    Str Bool
    CodeRef
);

sub Str {
    return sub {
        defined $_[0] && !ref $_[0]
            or croak "not a Str: $_[0]";
    };
}

sub Bool {
    return sub {
        !defined $_[0] || !ref $_[0]
            or croak "not a Bool: $_[0]";
    };
}

sub CodeRef {
    return sub {
        ref $_[0] eq 'CODE'
            or croak "not a CodeRef: $_[0]";
    }
}

sub to_Channels {
    return sub {
        ref $_[0] eq 'ARRAY' 
            ? $_[0]
            : [ $_[0] ]
    };
}

1;

__END__
class_type 'Entity',
    { class => 'Provision::DSL::Entity' };

class_type 'Source',
    { class => 'Provision::DSL::Source' };

class_type 'Resource',
    { class => 'Provision::DSL::Source::Resource' };

subtype 'SourceContent',
    as 'Str';
coerce 'SourceContent',
    from 'Source',
        via { $_->content };


subtype 'Permission',
    as 'Str',
    where { m{\A [0-7]{3,} \z}xms },
    message { 'a permission must be a 3-digit octal number' };


class_type 'PathClassEntity',
    { class => 'Path::Class::Entity' };
coerce 'PathClassEntity',
    from 'Str',
        via { -d $_ 
                ? Path::Class::Dir->new($_) 
                : Path::Class::File->new($_) 
            },
    from 'Resource',
        via { -d $_->path 
                ? Path::Class::Dir->new($_->path) 
                : Path::Class::File->new($_->path) 
            };


class_type 'PathClassFile',
    { class => 'Path::Class::File' };
coerce 'PathClassFile',
    from 'Str',
        via { Path::Class::File->new($_) };


class_type 'PathClassDir',
    { class => 'Path::Class::Dir' };
coerce 'PathClassDir',
    from 'Str',
        via { Path::Class::Dir->new($_) },
    from 'Resource',
        via { Path::Class::Dir->new($_->path) };


subtype 'ExistingDir',
    as 'PathClassDir',
    where { -d $_ },
    message { "Directory $_ does not exist" };
coerce 'ExistingDir',
    from 'Str',
        via { Path::Class::Dir->new($_)->resolve->absolute },
    from 'Resource',
        via { Path::Class::Dir->new($_->path) };


subtype 'ExistingFile',
    as 'PathClassFile',
    where { -f $_ },
    message { "File $_ does not exist" };
coerce 'ExistingFile',
    from 'Str',
        via { Path::Class::Dir->new($_)->resolve->absolute },
    from 'Resource',
        via { Path::Class::Dir->new($_->path) };


subtype 'ExecutableFile',
    as 'ExistingFile',
    where { -x $_ },
    message { "File $_ is not executable" };
coerce 'ExecutableFile',
    from 'Str',
        via { Path::Class::Dir->new($_)->resolve->absolute },
    from 'Resource',
        via { Path::Class::Dir->new($_->path) };


subtype 'DirList',
    as 'ArrayRef',
    where { !grep { ref $_ ne 'HASH' || !exists $_->{path} } @$_ },
    message { 'invalid content for a dirlist' };
coerce 'DirList',
    from 'Str',
        via { [ { path => $_ } ] },
    from 'ArrayRef',
        via { [ map { ref $_ ? $_ : { path => $_ } } @$_ ] };


subtype 'Channels',
    as 'ArrayRef',
coerce 'Channels',
    from 'Str',
        via { [ $_ ] };


no Moose::Util::TypeConstraints;
1;
