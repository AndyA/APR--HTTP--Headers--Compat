package APR::HTTP::Headers::Compat::MagicHash;

use strict;
use warnings;

use APR::Table;
use Carp qw( confess );
use HTTP::Headers;
use Storable qw( dclone );

=head1 NAME

APR::HTTP::Headers::Compat::MagicHash - Tie a hash to an APR::Table

=cut

sub TIEHASH {
  my ( $class, $table, %args ) = @_;

  my $self = bless {
    hash  => {},
    keys  => [],
    table => $table,
  }, $class;

  while ( my ( $k, $v ) = each %args ) {
    $self->STORE( $k, $v );
  }

  return $self;
}

=head2 C<< table >>

Get the table object.

=cut

sub table { shift->{table} }

sub _nicename {
  my ( $self, @names ) = @_;

  my $hdr    = HTTP::Headers->new( map { $_ => 1 } @names );
  my @nice   = $hdr->header_field_names;
  my %lookup = map { lc $_ => $_ } @nice;
  my @r = map { $lookup{$_} or confess "No mapping for $_" } @names;
  return wantarray ? @r : $r[0];
}

sub _nicefor {
  my ( $self, $name ) = @_;
  return $1 if $name =~ /^:(.+)/;
  return $self->{namemap}{$name} ||= $self->_nicename( $name );
}

sub FETCH {
  my ( $self, $key ) = @_;
  return $self->{hash}{ $self->_nicefor( $key ) };
}

sub STORE {
  my ( $self, $key, $value ) = @_;
  my $nkey = $self->_nicefor( $key );
  push @{ $self->{keys} }, $key
   unless exists $self->{hash}{$nkey};
  $self->{hash}{$nkey} = $value;
}

sub DELETE {
  my ( $self, $key ) = @_;
  my $nkey = $self->_nicefor( $key );
  @{ $self->{keys} } = grep { $_ ne $key } @{ $self->{keys} };
  delete $self->{hash}{$nkey};
}

sub CLEAR {
  my ( $self ) = @_;
  $self->{hash} = {};
  $self->{keys} = [];
  $self->{table}->clear;
}

sub EXISTS {
  my ( $self, $key ) = @_;
  return exists $self->{hash}{ $self->_nicefor( $key ) };
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
  #    use Data::Dumper;
  #    print STDERR "# ", Dumper($self);
}

sub UNTIE {
  my ( $self ) = @_;
}

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl
