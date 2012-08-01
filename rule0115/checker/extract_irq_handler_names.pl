#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;
use 5.10.0;
use feature qw(say);

undef $/;

my $file = <>;

my @exported = $file =~ m/request_irq\s*\([^,]+,\s*(\w+)\s*,[^,]+,[^,]+,[^)]+\)\s*;/gm;
push @exported, $file =~ m/request_threaded_irq\s*\([^,]+,\s*(\w+)\s*,[^,]+,[^,]+,[^,]+,[^)]+\)\s*;/gm;

say "@exported";

