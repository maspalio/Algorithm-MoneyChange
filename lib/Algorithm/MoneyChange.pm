#
# Package.
#

package Algorithm::MoneyChange;

#
# Export.
#

use Exporter 'import';

@EXPORT_OK = qw(
  build_graph
  coin_attribute
  coins_sets
  done_attribute
  edge_attribute
  rip_sets
);

#
# Bitch.
#

use 5.006;
use strict;
use warnings FATAL => 'all';

#
# Dependencies.
#

use Graph::Easy;

#
# Documentation.
#

=head1 NAME

Algorithm::MoneyChange - The great new Algorithm::MoneyChange!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Money change problem, as per SICP's L<Tree Recursion|http://mitpress.mit.edu/sicp/full-text/book/book-Z-H-11.html#%_sec_1.2.2>.

Same walking algorithm but first degenerate case is used to build a "done" (i.e., label == '---') leaf node.
Coins sets are ripped by walking tree from root to these nodes, harvesting "coin" (i.e., labeled with a coin value) edges.

Use it like:

    use Algorithm::MoneyChange qw( coins_sets build_graph rip_sets );
    
    # either:
    my $sets = coins_sets ({ amount => 10, denominations => [ qw( 2 5 10 ) ] });
    # or:
    my $graph = build_graph ({ amount => 10, denominations => [ qw( 2 5 10 ) ] });
    my $sets  = rip_sets ({ graph => $graph });
    
    use YAML::XS qw( Dump );
    print Dump ( $sets );
    ---
    - - 2
      - 2
      - 2
      - 2
      - 2
    - - 5
      - 5
    - - 10
    
    print + $graph->as_ascii;
    +-------------------+     +---------------+     +------------+  2   +-----------+  2   +-----------+  2   +-----------+  2   +-----------+  2   +-----+
    | 10 ~ [ 10, 5, 2 ] | --> | 10 ~ [ 5, 2 ] | --> | 10 ~ [ 2 ] | ---> | 8 ~ [ 2 ] | ---> | 6 ~ [ 2 ] | ---> | 4 ~ [ 2 ] | ---> | 2 ~ [ 2 ] | ---> | --- |
    +-------------------+     +---------------+     +------------+      +-----------+      +-----------+      +-----------+      +-----------+      +-----+
      |                         |
      | 10                      | 5
      v                         v
    +-------------------+     +---------------+     +------------+  2   +-----------+  2   +-----------+
    |        ---        |     | 5 ~ [ 5, 2 ]  | --> | 5 ~ [ 2 ]  | ---> | 3 ~ [ 2 ] | ---> | 1 ~ [ 2 ] |
    +-------------------+     +---------------+     +------------+      +-----------+      +-----------+
                                |
                                | 5
                                v
                              +---------------+
                              |      ---      |
                              +---------------+

L</build_graph> function returns a L<Graph::Easy> instance.

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

    build_graph
    coin_attribute
    coins_sets
    done_attribute
    edge_attribute
    rip_sets

=head1 SUBROUTINES

=cut

#
# Globals.
#

my $DONE = { color => 'DarkSlateGrey', label => '---', shape => 'octagon', fill => 'Chartreuse' };
my $EDGE = { color => 'gray' };
my $COIN = { color => 'ForestGreen' };

my ( $ID, $FIRST_DENOMINATION );

#
# Graph.
#

sub _attribute {
  my ( $h, $a ) = @_;
  
  if ( ref $a eq 'HASH' ) {
    $h = $a;
  }
  elsif ( $a ) {
    return $h->{$a};
  }
  
  return $h;
}

sub done_attribute { return _attribute ( $DONE => shift ) }
sub edge_attribute { return _attribute ( $EDGE => shift ) }
sub coin_attribute { return _attribute ( $COIN => shift ) }

sub reset_node_name {
  $ID = 0;
}

sub new_node_name {
  return 'N' . $ID++;
}

sub add_node {
  my ( $option ) = @_;
  
  my $n = $option->{graph}->add_node ( my $name = new_node_name () );
  
  $n->set_attribute ( title => $name ) unless $option->{attribute}->{title};
  
  if ( $option->{attribute} ) {
    $n->set_attribute ( $_ => $option->{attribute}->{$_} ) for keys %{$option->{attribute}};
  }
  
  return $n;
}

sub add_edge {
  my ( $option ) = @_;
  
  return unless $option->{rhs};
  
  my $e = $option->{graph}->add_edge ( $option->{lhs}, $option->{rhs} );
  
  if ( $option->{attribute} ) {
    $e->set_attribute ( $_ => $option->{attribute}->{$_} ) for keys %{$option->{attribute}};
  }
  if ( $option->{label} ) {
    $e->set_attribute ( label => $option->{label} );
  }
  
  return $e;
}

sub new_graph {
  my ( $option ) = @_;
  
  reset_node_name ();
  
  return Graph::Easy->new ( $option // {} );
}

#
# Denominations.
#

sub build_first_denomination {
  my ( $denominations ) = @_;
  
  undef $FIRST_DENOMINATION;
  
  my $i = 1;
  
  $FIRST_DENOMINATION->{$i++} = $_ for @$denominations;
}

sub first_denomination {
  my ( $kinds_of_coins ) = @_;
  
  return $FIRST_DENOMINATION->{$kinds_of_coins};
}

sub first_denominations {
  my ( $kinds_of_coins ) = @_;
  
  return map { $FIRST_DENOMINATION->{$_} } sort { $b cmp $a } grep { $_ <= $kinds_of_coins } keys %$FIRST_DENOMINATION;
}

#
# Build.
#

sub _build_graph {
  my ( $g, $amount, $kinds_of_coins ) = @_;
  
  return 0 if $kinds_of_coins == 0 || $amount < 0;
  
  return add_node ({ graph => $g, attribute => done_attribute () }) if $amount == 0;
  
  my $n = add_node ({ graph => $g, attribute => { label => "$amount ~ [ " . join ( ", ", first_denominations ( $kinds_of_coins ) ) . " ]" } });
  
  my $denomination = first_denomination ( $kinds_of_coins );
  
  add_edge ({ graph => $g, lhs => $n, rhs => _build_graph ( $g, $amount,                 $kinds_of_coins - 1 ), attribute => edge_attribute () });
  add_edge ({ graph => $g, lhs => $n, rhs => _build_graph ( $g, $amount - $denomination, $kinds_of_coins     ), attribute => coin_attribute (), label => $denomination });
  
  return $n;
}

sub build_graph {
  my ( $option ) = @_;
  
  build_first_denomination ( $option->{denominations} );
  
  my $g = new_graph ( $option->{graph_option} );
  
  _build_graph ( $g, $option->{amount}, scalar ( keys %$FIRST_DENOMINATION ) );
  
  return $g;
}

#
# Walk.
#

sub rip_sets {
  my ( $option ) = @_;
    
  my ( $sets, $ls, $walk_ );
  
  my $walk = sub {
    my ( $n ) = @_;

    return $sets unless $n;

    if ( $n->label eq done_attribute ( 'label' ) ) {
      push @$sets, [ sort { $b cmp $a } @$ls ];

      return $sets;
    }

    for my $e ( $n->outgoing ) {
      my $l = $e->label;

      push @$ls, $l if $l;

      $walk_->( $e->to );

      pop @$ls if $l;
    }
    
    return $sets;
  };
  
  $walk_ = $walk;
  
  my $root = ( $option->{graph}->source_nodes )[0];
  
  return sort_sets ( $walk->( $root, [] ) );
}

#
# Sort.
#

sub sort_sets {
  my ( $sets ) = @_;
  
  return [ map { $_->[1] } sort { $a->[0] <=> $b->[0] } map { [ scalar ( @$_ ) . '.' . $_->[0], $_ ] } @$sets ];
}

#
# Core.
#

sub coins_sets {
  my ( $option ) = @_;
  
  if ( my $g = build_graph ( $option ) ) {
    return rip_sets ({ graph => $g });
  }
  
  return;
}

=head1 AUTHOR

Xavier Caron, C<< <xcaron at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-algorithm-moneychange at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Algorithm-MoneyChange>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Algorithm::MoneyChange


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Algorithm-MoneyChange>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Algorithm-MoneyChange>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Algorithm-MoneyChange>

=item * Search CPAN

L<http://search.cpan.org/dist/Algorithm-MoneyChange/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Xavier Caron.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Algorithm::MoneyChange
