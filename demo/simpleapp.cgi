#!/usr/bin/perl -w

use strict;
use lib '.';
use lib '/usr/local/lib/perl5/site_perl/5.6.1';
use SimpleApp;
my $simple_app = obtain SimpleApp;
$simple_app->cycle;
