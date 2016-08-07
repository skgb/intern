#!/usr/bin/env perl

use strict;
use warnings;

use 5.016;  # enable the full feature package of Perl 5.22 incl. full unicode
use 5.022;  # fail with clear error message if switching to perlbrew failed

use lib 'lib';

# Start command line interface for application
require Mojolicious::Commands;
Mojolicious::Commands->start_app('SKGB::Intern');

# $ morbo script/skgb_intern.pl
