#!/usr/bin/env perl

use Algorithm::MoneyChange qw( coins_sets build_graph rip_sets );

use Test::More;
use Test::Differences;

my @cases = (
  {
    amount        => 10,
    denominations => [ qw( 2 5 10 ) ],
    expected      => [
      [ 10 ],
      [ 5, 5 ],
      [ 2, 2, 2, 2, 2 ],
    ],
  },
  {
    amount        => 10,
    denominations => [ qw( 5 10 2 ) ],
    expected      => [
      [ 10 ],
      [ 5, 5 ],
      [ 2, 2, 2, 2, 2 ],
    ],
  },
  {
    amount        => 10,
    denominations => [ qw( 2 5 10 1 ) ],
    expected      => [
      [ 10 ],
      [ 5, 5 ],
      [ 5, 2, 2, 1 ],
      [ 2, 2, 2, 2, 2 ],
      [ 5, 2, 1, 1, 1 ],
      [ 2, 2, 2, 2, 1, 1 ],
      [ 5, 1, 1, 1, 1, 1 ],
      [ 2, 2, 2, 1, 1, 1, 1 ],
      [ 2, 2, 1, 1, 1, 1, 1, 1 ],
      [ 2, 1, 1, 1, 1, 1, 1, 1, 1 ],
      [ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
    ],
  },
  {
    amount        => 10,
    denominations => [ qw( 10 ) ],
    expected      => [
      [ 10 ],
    ],
  },
  {
    amount        => 10,
    denominations => [ qw( 11 ) ],
    expected      => [
    ],
  },
);

plan tests => 2 * @cases;

for ( @cases ) {
  my $description = "$_->{amount} ~ [ qw( @{$_->{denominations}} ) ]";
  
  eq_or_diff ( coins_sets ( $_ ),                          $_->{expected}, "$description (1)"  );
  eq_or_diff ( rip_sets ({ graph => build_graph ( $_ ) }), $_->{expected}, "$description (2)"  );
}
