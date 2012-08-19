package Provision::DSL::Types;
use Path::Class;
use Scalar::Util 'blessed';
use Carp;
use base 'Exporter';

our @EXPORT = qw(
    Str Int Bool
    State
    CodeRef
    ExistingDir ExistingFile ExecutableFile
    PerlVersion

    to_Str
    to_Content
    to_Channels
    to_Dir to_ExistingDir to_File
    to_User to_Group
    to_Permission to_PerlVersion
);

sub Str {
    return sub {
        defined $_[0] && !ref $_[0]
            or croak "not a Str: $_[0]";
    };
}

sub Int {
    return sub {
        defined $_[0] && !ref $_[0] && $_[0] =~ m{\A \d+ \z}xms
            or croak "not an Int: $_[0]";
    };
}

sub Bool {
    return sub {
        !defined $_[0] || !ref $_[0]
            or croak "not a Bool: $_[0]";
    };
}

sub State {
    return sub {
        defined $_[0] && !ref $_[0] && $_[0] =~ m{\A (?:missing|outdated|current) \z}xms
            or croak "not a valid State: $_[0]";
    };
}

sub CodeRef {
    return sub {
        ref $_[0] eq 'CODE'
            or croak "not a CodeRef: $_[0]";
    }
}

sub ExistingDir {
    return sub { -d $_[0] or croak "dir '$_[0]' does not exist" }
}

sub ExistingFile {
    return sub { -f $_[0] or croak "file '$_[0]' does not exist" }
}

sub ExecutableFile {
    return sub { -x $_[0] or croak "file '$_[0]' is not executable" }
}

sub PerlVersion {
    return sub {
        $_[0] =~ m{\A perl- \d+\.\d+\.\d+(?:-RC\d+)? \z}xms
        or croak "'$_' does not look like a perl version"
    }
}


sub to_Str {
    return sub { "$_[0]" }
}

sub to_Content {
    return sub {
        blessed $_[0] && $_[0]->can('content')
            ? $_[0]->content
        : ref $_[0] eq 'Path::Class::File'
            ? scalar $_[0]->slurp
        : "$_[0]"
    }
}

sub to_Channels {
    return sub { ref $_[0] eq 'ARRAY' ? $_[0] : [ $_[0] ] }
}

sub to_Dir {
    return sub { dir($_[0])->absolute->cleanup }
}

sub to_ExistingDir {
    return sub {
        (
            blessed $_[0] && $_[0]->can('path')
                ? $_[0]->path
                : dir($_[0])
        )->absolute->resolve
    }
}

sub to_File {
    return sub { file($_[0])->absolute->cleanup }
}

sub to_User {
    return sub {
        blessed $_[0] && $_[0]->isa('Provision::DSL::Entity::User')
            ? $_[0]
            : Provision::DSL::App->instance->get_or_create_entity(
                'User',
                $_[0] =~ m{\D}
                    ? $_[0]
                    : scalar getpwuid($_[0])
            );
    }
}

sub to_Group {
    return sub {
        blessed $_[0] && $_[0]->isa('Provision::DSL::Entity::Group')
            ? $_[0]
            : Provision::DSL::App->instance->get_or_create_entity(
                'Group',
                $_[0] =~ m{\D}
                    ? $_[0]
                    : scalar getgrgid($_[0])
            );
    }
}

sub to_Permission {
    return sub {
        $_[0] =~ m{\A 0[0-7]+ \z}xms
            ? oct $_[0]
            : $_[0] + 0;
    };
}

sub to_PerlVersion {
    return sub { "perl-$_[0]" };
}

1;
