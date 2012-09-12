package Provision::DSL;
use strict;
use warnings;
use feature ':5.10';
use Module::Pluggable search_path => 'Provision::DSL::Entity',
                      sub_name => 'entities';
use Module::Pluggable search_path => 'Provision::DSL::Source',
                      sub_name => 'sources';
use Module::Load;
use Path::Class;

=head1 NAME

Provision::DSL - a simple provisioning toolkit

=head1 DESCRIPTION

See L<Provision::DSL::Manual> for a comprehensive description

=cut

our @EXPORT = qw(Done done OS Os os Defaults Files files app);
our %default_for_entity;

sub app;

END {
    say STDERR '"Done()" not called or missing. Provisioning failed.'
        if !$? && !app->is_running;
}

sub import {
    my $package = caller;

    warnings->import();
    strict->import();
    feature->import(':5.10');

    instantiate_app(@ARGV);
    create_and_export_entity_keywords($package);
    create_and_export_source_keywords($package);
    export_symbols($package);
    turn_on_autoflush($package);

    app->log_debug('init done');
}

sub instantiate_app {
    my @argv = @_;

    my $os = os();
    my $app_package = "Provision::DSL::App::$os";
    load $app_package;

    $app_package->instance(@argv);
}

sub app { Provision::DSL::App->instance }

sub create_and_export_entity_keywords {
    my $package = shift;

    my $os = os();
    my %package_for;
    foreach my $entity_package (__PACKAGE__->entities) {
        my $entity_name = $entity_package;
        $entity_name =~ s{\A Provision::DSL::Entity::(?:_(\w+)\::)?}{}xms;
        next if $1 && $1 ne $os;

        $entity_name =~ s{::}{_}xmsg;

        next if exists $package_for{$entity_name}
             && length $package_for{$entity_name} > length $entity_package;
        $package_for{$entity_name} = $entity_package;

        # create class-types and coercions before loading entity modules
        # if (!find_type_constraint($entity_name)) {
        #     class_type $entity_name,
        #         { class => $entity_package };
        #     coerce $entity_name,
        #         from 'Str',
        #         via { $entity_package->new({app => $app, name => $_}) };
        # }
    }
    app->entity_package_for(\%package_for);

    while (my ($entity_name, $entity_package) = each %package_for) {
        load $entity_package;

        no strict 'refs';
        no warnings 'redefine';
        *{"${package}::${entity_name}"} = sub {
            if (defined wantarray) {
                return app->get_cached_entity($entity_name, @_);
            } else {
                my %args = exists $default_for_entity{$entity_name}
                    ? %{$default_for_entity{$entity_name}}
                    : ();
                $args{name} = shift if !ref $_[0];

                %args = (%args, ref $_[0] eq 'HASH' ? %{$_[0]} : @_);

                app->add_entity_for_install(
                    app->create_entity($entity_name, \%args)
                );
            }
        };
    }
}

sub create_and_export_source_keywords {
    my $package = shift;

    foreach my $source_package (__PACKAGE__->sources) {
        load $source_package;

        my $source_name = $source_package;
        $source_name =~ s{\A Provision::DSL::Source::}{}xms;

        no strict 'refs';
        no warnings 'redefine'; # occurs during test
        *{"${package}::${source_name}"}   = sub { $source_package->new(@_) };
        *{"${package}::\l${source_name}"} = *{"${package}::${source_name}"};
    }
}

sub export_symbols {
    my $package = shift;

    foreach my $symbol (@EXPORT) {
        no strict 'refs';
        *{"${package}::${symbol}"} = *{"Provision::DSL::$symbol"};
    }
}

sub turn_on_autoflush {
    my $package = shift;

    no strict 'refs';
    ${"$package\::|"} = 1;
}

sub OS { goto &os }
sub Os { goto &os }
sub os {
    if ($^O eq 'darwin') {
        return 'OSX';
    } else {
        return 'Ubuntu'; ### FIXME: maybe wrong!
    }
}

sub Done { goto &done }
sub done {
    app->install_all_entities;
}

sub Defaults {
    my %d = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

    @default_for_entity{keys %d} = values %d;
}

sub Files { goto &files }
sub files {
    my @files;

    foreach my $dir (map {-d $_ ? dir($_) : () } @_) {
        $dir->traverse( sub {
            my ($child, $cont) = @_;

            push @files, $child if -f $child;
            $cont->();
        });
    }

    return \@files;
}

=head1 AUTHOR

Wolfgang Kinkeldei, E<lt>wolfgang@kinkeldei.deE<gt>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
