package Provision::DSL::Source::Bin;
use Moo;
use FindBin;

extends 'Provision::DSL::Source::Resource';

sub _build_root_dir {
    (
        grep { -d }
        "$FindBin::Bin/local/bin",              # controlled machine
        "$FindBin::Bin/.provision_lib/bin",     # controlling machine
        "$FindBin::Bin/bin",                    # while testing
    )[0]
}

1;
