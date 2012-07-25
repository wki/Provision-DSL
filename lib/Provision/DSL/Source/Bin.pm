package Provision::DSL::Source::Bin;
use Moo;

extends 'Provision::DSL::Source::Resource';

sub _build_root_dir { "$FindBin::Bin/local/bin" }

1;
