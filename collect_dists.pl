#!/usr/bin/env perl
use strict;
use warnings;
use autodie;
use 5.010;
use FindBin;
use Config;


my $install_dir = "$FindBin::Bin/share";


clean_install_dir();
install_distributions();
remove_superfluous_files();

fetch_perlbrew_installer();
exit;


sub clean_install_dir {
    system "rm -rf $install_dir/*";
}

sub install_distributions {
    foreach my $url (<DATA>) {
        chomp $url;

        my $dist = $url;
        $dist =~ s{\A .* / | \.tar\.gz \z}{}xms;
        
        say "installing $dist...";
        system "cpanm --notest -l '$install_dir' '$url'"
    }
}

sub remove_superfluous_files {
    system "rm -rf '$install_dir/man'";
    system "rm -rf '$install_dir/lib/perl5/$Config{archname}'";
    system "find '$install_dir' -name '*.pod' -exec rm {} ';'";
}

sub fetch_perlbrew_installer {
    system "mkdir -p '$install_dir/bin'";
    system "curl -s -L http://install.perlbrew.pl -o '$install_dir/bin/install.perlbrew.sh'"
}

#
# all packages needed on the remote side are collected below.
# Reason: Path::Class~0.32 depends on a recent version of File::Spec
#
__DATA__
http://cpan.metacpan.org/authors/id/P/PJ/PJF/autodie-2.17.tar.gz
http://cpan.metacpan.org/authors/id/E/ET/ETHER/strictures-1.004004.tar.gz
http://cpan.metacpan.org/authors/id/F/FR/FREW/Sub-Exporter-Progressive-0.001010.tar.gz
http://cpan.metacpan.org/authors/id/H/HA/HAARG/Devel-GlobalDestruction-0.11.tar.gz
http://cpan.metacpan.org/authors/id/E/ET/ETHER/Class-Method-Modifiers-2.04.tar.gz
http://cpan.metacpan.org/authors/id/M/MS/MSTROUT/Role-Tiny-1.002005.tar.gz
http://cpan.metacpan.org/authors/id/D/DO/DOY/Try-Tiny-0.12.tar.gz
http://cpan.metacpan.org/authors/id/R/RJ/RJBS/IPC-Run3-0.045.tar.gz
http://cpan.metacpan.org/authors/id/S/SI/SIMONW/Module-Pluggable-4.7.tar.gz
http://cpan.metacpan.org/authors/id/Z/ZE/ZEFRAM/Module-Runtime-0.013.tar.gz
http://cpan.metacpan.org/authors/id/B/BI/BINGOS/Module-Load-0.24.tar.gz
http://cpan.metacpan.org/authors/id/M/MS/MSTROUT/Moo-1.002000.tar.gz
http://cpan.metacpan.org/authors/id/B/BO/BOBTFISH/MRO-Compat-0.12.tar.gz
http://cpan.metacpan.org/authors/id/F/FL/FLORA/Class-C3-0.24.tar.gz
http://cpan.metacpan.org/authors/id/F/FL/FLORA/Algorithm-C3-0.08.tar.gz
http://cpan.metacpan.org/authors/id/D/DA/DAGOLDEN/HTTP-Tiny-0.029.tar.gz
http://cpan.metacpan.org/authors/id/U/UR/URI/Template-Simple-0.06.tar.gz
http://cpan.metacpan.org/authors/id/U/UR/URI/File-Slurp-9999.19.tar.gz
http://cpan.metacpan.org/authors/id/K/KW/KWILLIAMS/Path-Class-0.31.tar.gz
http://cpan.metacpan.org/authors/id/T/TO/TOKUHIROM/File-Zglob-0.11.tar.gz
