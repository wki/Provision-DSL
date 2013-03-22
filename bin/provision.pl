#!/usr/bin/env perl
use Provision::DSL::Script::Provision;

Provision::DSL::Script::Provision->instance(@ARGV)->run();
# Provision::DSL::Script::Provision->new_with_options(@ARGV)->run();
