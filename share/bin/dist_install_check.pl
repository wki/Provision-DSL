#!/usr/bin/env perl
use strict;
use warnings;

my @missing_modules;
my @outdated_modules;

while (<>) {
    s{\A\s+|\s+\z}{}xmsg;
    my ($module, $version) = split '~';
    next if !$module;
    
    if (!eval "use $module; 1") {
        push @missing_modules, $module;
    } elsif ($version && !eval "use $module $version; 1") {
        $@ =~ s{\sat\s.*}{}xms;
        push @outdated_modules, $@;
    }
}

exit if !@missing_modules && !@outdated_modules;

print STDERR "Missing: $_\n" for @missing_modules;
print STDERR "$_\n" for @outdated_modules;
exit 1;
