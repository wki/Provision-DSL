#!/usr/bin/env perl
use Provision::DSL::Local;

Provision::DSL::Local->instance(@ARGV)->run();
