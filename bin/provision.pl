#!/usr/bin/env perl
use Provision::DSL::Command::Provision;

Provision::DSL::Command::Provision->new_with_options(@ARGV)->run();
