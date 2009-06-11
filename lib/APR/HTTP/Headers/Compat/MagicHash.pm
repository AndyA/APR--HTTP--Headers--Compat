package APR::HTTP::Headers::Compat::MagicHash;

use strict;
use warnings;

use APR::Table;

=head1 NAME

APR::HTTP::Headers::Compat::MagicHash - Tie a hash to an APR::Table

=cut

sub TIEHASH {
  my ( $class, %args ) = @_;
  bless {
    hash => \%args,
    keys => [ keys %args ],
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
  @{ $self->{keys} } = grep { $_ ne $key } @{ $self->{keys} };
  delete $self->{hash}{$key};
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

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl
