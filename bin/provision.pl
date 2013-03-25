#!/usr/bin/env perl
use Provision::DSL::Local;

exit Provision::DSL::Local->instance(@ARGV)->run;
