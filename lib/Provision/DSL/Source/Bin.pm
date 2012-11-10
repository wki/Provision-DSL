package Provision::DSL::Source::Bin;
use Moo;
use FindBin;

extends 'Provision::DSL::Source::Resource';

sub _build_root_dir {
    (
        grep { -d }
        "$FindBin::Bin/bin",                    # testing + controlled machine
        "$FindBin::Bin/.provision_lib/bin",     # WRONG: controlling machine
    )[0]
}

1;
