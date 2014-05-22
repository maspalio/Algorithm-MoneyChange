#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Algorithm::MoneyChange' ) || print "Bail out!\n";
}

diag( "Testing Algorithm::MoneyChange $Algorithm::MoneyChange::VERSION, Perl $], $^X" );
