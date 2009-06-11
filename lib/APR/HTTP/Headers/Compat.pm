package APR::HTTP::Headers::Compat;

use warnings;
use strict;

use Carp;
use APR::HTTP::Headers::Compat::MagicHash;

use base qw( HTTP::Headers );

=head1 NAME

APR::HTTP::Headers::Compat - Make an APR::Table look like an HTTP::Headers

=head1 VERSION

This document describes APR::HTTP::Headers::Compat version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  use APR::HTTP::Headers::Compat;

=head1 DESCRIPTION

=head1 INTERFACE 

=head2 C<< new >>

=cut

sub new {
  my ( $class, $table ) = ( shift, shift );
  my %self = %{ $class->SUPER::new( @_ ) };
  tie %self, 'APR::HTTP::Headers::Compat::MagicHash', $table, %self;
  return bless \%self, $class;
}

sub _magic { tied %{ shift() } }

=head2 C<< clone >>

Clone this object. The clone is a regular L<HTTP::Headers> object.

=cut

sub clone { bless { %{ shift() } }, 'HTTP::Headers' }

=head2 C<< table >>

Get the underlying L<APR::Table> object.

=cut

sub table { shift->_magic->table }

=head2 C<< remove_content_headers >>

=cut

sub remove_content_headers {
  my $self = shift;

  return $self->SUPER::remove_content_headers( @_ )
   unless defined wantarray;

  # This gets nasty. We downbless ourself to be an HTTP::Headers so that
  # when HTTP::Headers->remove_content_headers does
  #
  #   my $c = ref( $self )->new
  #
  # it creates a new HTTP::Headers instead of attempting to create a
  # new APR::HTTP::Headers::Compat.

  my $class = ref $self;
  bless $self, 'HTTP::Headers';
  $DB::single = 1;
  my $other = $self->remove_content_headers( @_ );
  bless $self, $class;

  # Return a non-magic HTTP::Headers
  return $other;
}

1;
__END__

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-apr-http-headers-compat@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Andy Armstrong C<< <andy@hexten.net> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
