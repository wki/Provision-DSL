#!/usr/bin/env perl
use strict;
use warnings;

my @missing_modules;
my @outdated_modules;
my $i;

sub is_missing {
    local $" = ' ';
    $i++;

    # package needed because Moose* classes apply a meta class
    # and this should only happen once per package
    eval "package x$i; use @_; 1";

    return $@;
}

while (<>) {
    s{\A\s+|\s+\z}{}xmsg;
    my ($module, $version) = split '~';
    next if !$module;
    
    if (is_missing $module) {
        push @missing_modules, $module;
    } elsif ($version && is_missing $module, $version) {
        $@ =~ s{\sat\s.*}{}xms;
        push @outdated_modules, $@;
    }
}

exit if !@missing_modules && !@outdated_modules;

print STDERR "Missing: $_\n" for @missing_modules;
print STDERR "$_\n"          for @outdated_modules;
exit 1;
