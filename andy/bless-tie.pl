#!/usr/bin/env perl

package MyHash;

use strict;
use warnings;

sub TIEHASH {
  my ( $class, @args ) = @_;
  bless {
    hash => {},
    keys => [],
  }, $class;
}

sub FETCH {
  my ( $self, $key ) = @_;
  return $self->{hash}{$key};
}

sub STORE {
  my ( $self, $key, $value ) = @_;
  push @{ $self->{keys} }, $key
   unless exists $self->{hash}{$key};
  $self->{hash}{$key} = $value;
}

sub DELETE {
  my ( $self, $key ) = @_;
  delete $self->{hash}{$key};
  @{ $self->{keys} } = grep { $_ ne $key } @{ $self->{keys} };
}

sub CLEAR {
  my ( $self ) = @_;
  $self->{hash} = {};
  $self->{keys} = [];
}

sub EXISTS {
  my ( $self, $key ) = @_;
  return exists $self->{hash}{$key};
}

sub FIRSTKEY {
  my ( $self ) = @_;
  $self->{pos} = 0;
  return $self->{keys}[0];
}

sub NEXTKEY {
  my ( $self, $lastkey ) = @_;
  unless ( $self->{keys}[ $self->{pos} ] eq $lastkey ) {
    my $nk = scalar @{ $self->{keys} };
    for my $i ( 0 .. $nk ) {
      if ( $self->{keys}[$i] eq $lastkey ) {
        $self->{pos} = $i;
        last;
      }
    }
  }
  return $self->{keys}[ ++$self->{pos} ];
}

sub SCALAR {
  my ( $self ) = @_;
  return scalar %{ $self->{hash} };
}

sub DESTROY {
  my ( $self ) = @_;
}

sub UNTIE {
  my ( $self ) = @_;
}

package MyThing;

use strict;
use warnings;

sub new {
  my $class = shift;
  tie my %self, 'MyHash';
  return bless \%self, $class;
}

sub set {
  my ( $self, $k, $v ) = @_;
  $self->{$k} = $v;
  return $self;
}

package main;

use strict;
use warnings;
use Data::Dumper;

my $thing = MyThing->new;
$thing->set( foo => 1 )->set( bar => 2 )->set( baz => 3 );
print Dumper( $thing );
$thing->set( foo => 4 )->set( bat => 5 );
print Dumper( $thing );

# vim:ts=2:sw=2:sts=2:et:ft=perl

