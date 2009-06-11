package APR::HTTP::Headers::Compat;

use warnings;
use strict;

use Carp;

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
  my $class = shift;
  my $self  = $class->SUPER::new( @_ );
  return bless $self, $class;
}

=head2 C<< remove_header >>

=cut

sub remove_header {
  my ( $self, @fields ) = @_;
  return $self->SUPER::remove_header( @fields );
}

sub _header {
  my ( $self, $field, $val, $op ) = @_;
  return $self->SUPER::_header( $field, $val, $op );
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
