#!perl -w

use strict;

use Test::More tests => 163;
use APR::Pool;
use APR::Table;
use APR::HTTP::Headers::Compat;

my ( $h, $h2 );
sub j { join( "|", @_ ) }

my $Pool = APR::Pool->new;

sub mk(@) {
  my $table = APR::Table::make( $Pool, 10 );
  return APR::HTTP::Headers::Compat->new( $table, @_ );
}

$h = mk;
ok( $h );
is( ref( $h ),     "APR::HTTP::Headers::Compat" );
is( $h->as_string, "" );

$h = mk(
  foo => "bar",
  foo => "baaaaz",
  Foo => "baz"
);
is( $h->as_string, "Foo: bar\nFoo: baaaaz\nFoo: baz\n" );

$h = mk( foo => [ "bar", "baz" ] );
is( $h->as_string, "Foo: bar\nFoo: baz\n" );

$h = mk( foo => 1, bar => 2, foo_bar => 3 );
is( $h->as_string,        "Bar: 2\nFoo: 1\nFoo-Bar: 3\n" );
is( $h->as_string( ";" ), "Bar: 2;Foo: 1;Foo-Bar: 3;" );

is( $h->header( "Foo" ),            1 );
is( $h->header( "FOO" ),            1 );
is( j( $h->header( "foo" ) ),       1 );
is( $h->header( "foo-bar" ),        3 );
is( $h->header( "foo_bar" ),        3 );
is( $h->header( "Not-There" ),      undef );
is( j( $h->header( "Not-There" ) ), "" );
is( eval { $h->header }, undef );
ok( $@ );

is( $h->header( "Foo", 11 ), 1 );
is( $h->header( "Foo", [ 1, 1 ] ), 11 );
is( $h->header( "Foo" ),      "1, 1" );
is( j( $h->header( "Foo" ) ), "1|1" );
is( $h->header( foo => 11, Foo => 12, bar => 22 ), 2 );
is( $h->header( "Foo" ), "11, 12" );
is( $h->header( "Bar" ), 22 );
is( $h->header( "Bar", undef ), 22 );
is( j( $h->header( "bar", 22 ) ), "" );

$h->push_header( Bar => 22 );
is( $h->header( "Bar" ), "22, 22" );
$h->push_header( Bar => [ 23 .. 25 ] );
is( $h->header( "Bar" ),      "22, 22, 23, 24, 25" );
is( j( $h->header( "Bar" ) ), "22|22|23|24|25" );

$h->clear;
$h->header( Foo => 1 );
is( $h->as_string, "Foo: 1\n" );
$h->init_header( Foo => 2 );
$h->init_header( Bar => 2 );
is( $h->as_string, "Bar: 2\nFoo: 1\n" );
$h->init_header( Foo => [ 2, 3 ] );
$h->init_header( Baz => [ 2, 3 ] );
is( $h->as_string, "Bar: 2\nBaz: 2\nBaz: 3\nFoo: 1\n" );

eval { $h->init_header( A => 1, B => 2, C => 3 ) };
ok( $@ );
is( $h->as_string, "Bar: 2\nBaz: 2\nBaz: 3\nFoo: 1\n" );

is( $h->clone->remove_header( "Foo" ),                     1 );
is( $h->clone->remove_header( "Bar" ),                     1 );
is( $h->clone->remove_header( "Baz" ),                     2 );
is( $h->clone->remove_header( qw(Foo Bar Baz Not-There) ), 4 );
is( $h->clone->remove_header( "Not-There" ),               0 );
is( j( $h->clone->remove_header( "Foo" ) ),                1 );
is( j( $h->clone->remove_header( "Bar" ) ),                2 );
is( j( $h->clone->remove_header( "Baz" ) ),                "2|3" );
is( j( $h->clone->remove_header( qw(Foo Bar Baz Not-There) ) ),
  "1|2|2|3" );
is( j( $h->clone->remove_header( "Not-There" ) ), "" );

$h = mk(
  allow            => "GET",
  content          => "none",
  content_type     => "text/html",
  content_md5      => "dummy",
  content_encoding => "gzip",
  content_foo      => "bar",
  last_modified    => "yesterday",
  expires          => "tomorrow",
  etag             => "abc",
  date             => "today",
  user_agent       => "libwww-perl",
  zoo              => "foo",
);
is( $h->as_string, <<EOT);
Date: today
User-Agent: libwww-perl
ETag: abc
Allow: GET
Content-Encoding: gzip
Content-MD5: dummy
Content-Type: text/html
Expires: tomorrow
Last-Modified: yesterday
Content: none
Content-Foo: bar
Zoo: foo
EOT

$h2 = $h->clone;
is( $h->as_string, $h2->as_string );

is( $h->remove_content_headers->as_string, <<EOT);
Allow: GET
Content-Encoding: gzip
Content-MD5: dummy
Content-Type: text/html
Expires: tomorrow
Last-Modified: yesterday
Content-Foo: bar
EOT

is( $h->as_string, <<EOT);
Date: today
User-Agent: libwww-perl
ETag: abc
Content: none
Zoo: foo
EOT

# separate code path for the void context case, so test it as well
$h2->remove_content_headers;
is( $h->as_string, $h2->as_string );

$h->clear;
is( $h->as_string, "" );
undef( $h2 );

$h = mk;
is( $h->header_field_names,      0 );
is( j( $h->header_field_names ), "" );

$h = mk(
  etag         => 1,
  foo          => [ 2, 3 ],
  content_type => "text/plain"
);
is( $h->header_field_names,      3 );
is( j( $h->header_field_names ), "ETag|Content-Type|Foo" );

{
  my @tmp;
  $h->scan( sub { push( @tmp, @_ ) } );
  is( j( @tmp ), "ETag|1|Content-Type|text/plain|Foo|2|Foo|3" );

  @tmp = ();
  eval {
    $h->scan( sub { push( @tmp, @_ ); die if $_[0] eq "Content-Type" }
    );
  };
  ok( $@ );
  is( j( @tmp ), "ETag|1|Content-Type|text/plain" );

  @tmp = ();
  $h->scan( sub { push( @tmp, @_ ) } );
  is( j( @tmp ), "ETag|1|Content-Type|text/plain|Foo|2|Foo|3" );
}

# CONVENIENCE METHODS

$h = mk;
is( $h->date,                    undef );
is( $h->date( time ),            undef );
is( j( $h->header_field_names ), "Date" );
ok( $h->header( "Date" ) =~ /^[A-Z][a-z][a-z], \d\d .* GMT$/ );
{
  my $off = time - $h->date;
  ok( $off == 0 || $off == 1 );
}

if ( $] < 5.006 ) {
  Test::skip( "Can't call variable method", 1 ) for 1 .. 13;
}
else {
  # other date fields
  for my $field (
    qw(expires if_modified_since if_unmodified_since
    last_modified)
   ) {
    eval <<'EOT'; die $@ if $@;
    is($h->$field, undef);
    is($h->$field(time), undef);
    ok((time - $h->$field) =~ /^[01]$/);
EOT
  }
  is( j( $h->header_field_names ),
    "Date|If-Modified-Since|If-Unmodified-Since|Expires|Last-Modified"
  );
}

$h->clear;
is( $h->content_type,                         "" );
is( $h->content_type( "text/html" ),          "" );
is( $h->content_type,                         "text/html" );
is( $h->content_type( "   TEXT  / HTML   " ), "text/html" );
is( $h->content_type,                         "text/html" );
is( j( $h->content_type ),                    "text/html" );
is( $h->content_type( "text/html;\n charSet = \"ISO-8859-1\"; Foo=1 " ),
  "text/html" );
is( $h->content_type, "text/html" );
is( j( $h->content_type ),
  "text/html|charSet = \"ISO-8859-1\"; Foo=1 " );
is( $h->header( "content_type" ),
  "text/html;\n charSet = \"ISO-8859-1\"; Foo=1 " );
ok( $h->content_is_html );
ok( !$h->content_is_xhtml );
ok( !$h->content_is_xml );
$h->content_type( "application/xhtml+xml" );
ok( $h->content_is_html );
ok( $h->content_is_xhtml );
ok( $h->content_is_xml );
is( $h->content_type( "text/html;\n charSet = \"ISO-8859-1\"; Foo=1 " ),
  "application/xhtml+xml" );

is( $h->content_encoding,           undef );
is( $h->content_encoding( "gzip" ), undef );
is( $h->content_encoding,           "gzip" );
is( j( $h->header_field_names ),    "Content-Encoding|Content-Type" );

is( $h->content_language,         undef );
is( $h->content_language( "no" ), undef );
is( $h->content_language,         "no" );

is( $h->title,                     undef );
is( $h->title( "This is a test" ), undef );
is( $h->title,                     "This is a test" );

is( $h->user_agent,                  undef );
is( $h->user_agent( "Mozilla/1.2" ), undef );
is( $h->user_agent,                  "Mozilla/1.2" );

is( $h->server,                 undef );
is( $h->server( "Apache/2.1" ), undef );
is( $h->server,                 "Apache/2.1" );

is( $h->from( "Gisle\@ActiveState.com" ), undef );
ok( $h->header( "from", "Gisle\@ActiveState.com" ) );

is( $h->referer( "http://www.example.com" ), undef );
is( $h->referer,                             "http://www.example.com" );
is( $h->referrer,                            "http://www.example.com" );
is( $h->referer( "http://www.example.com/#bar" ),
  "http://www.example.com" );
is( $h->referer, "http://www.example.com/" );
{
  require URI;
  my $u = URI->new( "http://www.example.com#bar" );
  $h->referer( $u );
  is( $u->as_string,           "http://www.example.com#bar" );
  is( $h->referer->fragment,   undef );
  is( $h->referrer->as_string, "http://www.example.com" );
}

is( $h->as_string, <<EOT);
From: Gisle\@ActiveState.com
Referer: http://www.example.com
User-Agent: Mozilla/1.2
Server: Apache/2.1
Content-Encoding: gzip
Content-Language: no
Content-Type: text/html;
 charSet = "ISO-8859-1"; Foo=1
Title: This is a test
EOT

$h->clear;
is( $h->www_authenticate( "foo" ),   undef );
is( $h->www_authenticate( "bar" ),   "foo" );
is( $h->www_authenticate,            "bar" );
is( $h->proxy_authenticate( "foo" ), undef );
is( $h->proxy_authenticate( "bar" ), "foo" );
is( $h->proxy_authenticate,          "bar" );

is( $h->authorization_basic,        undef );
is( $h->authorization_basic( "u" ), undef );
is( $h->authorization_basic( "u", "p" ), "u:" );
is( $h->authorization_basic,      "u:p" );
is( j( $h->authorization_basic ), "u|p" );
is( $h->authorization,            "Basic dTpw" );

is( eval { $h->authorization_basic( "u2:p" ) }, undef );
ok( $@ );
is( j( $h->authorization_basic ), "u|p" );

is( $h->proxy_authorization_basic( "u2", "p2" ), undef );
is( j( $h->proxy_authorization_basic ), "u2|p2" );
is( $h->proxy_authorization,            "Basic dTI6cDI=" );

is( $h->as_string, <<EOT);
Authorization: Basic dTpw
Proxy-Authorization: Basic dTI6cDI=
Proxy-Authenticate: bar
WWW-Authenticate: bar
EOT

#---- old tests below -----

$h = mk(
  mime_version => "1.0",
  content_type => "text/html"
);

$h->header( URI => "http://www.oslonett.no/" );

is( $h->header( "MIME-Version" ), "1.0" );
is( $h->header( 'Uri' ),          "http://www.oslonett.no/" );

$h->header(
  "MY-header" => "foo",
  "Date"      => "somedate",
  "Accept"    => [ "text/plain", "image/*" ],
);
$h->push_header( "accept" => "audio/basic" );

is( $h->header( "date" ), "somedate" );

my @accept = $h->header( "accept" );
is( @accept, 3 );

$h->remove_header( "uri", "date" );

my $str = $h->as_string;
my $lines = ( $str =~ tr/\n/\n/ );
is( $lines, 6 );

$h2 = $h->clone;

$h->header( "accept", "*/*" );
$h->remove_header( "my-header" );

@accept = $h2->header( "accept" );
is( @accept, 3 );

@accept = $h->header( "accept" );
is( @accept, 1 );

# Check order of headers, but first remove this one
$h2->remove_header( 'mime_version' );

# and add this general header
$h2->header( Connection => 'close' );

my @x = ();
$h2->scan( sub { push( @x, shift ); } );
is( join( ";", @x ),
  "Connection;Accept;Accept;Accept;Content-Type;MY-Header" );

# Check headers with embedded newlines:
$h = mk(
  a => "foo\n\n",
  b => "foo\nbar",
  c => "foo\n\nbar\n\n",
  d => "foo\n\tbar",
  e => "foo\n  bar  ",
  f => "foo\n bar\n  baz\nbaz",
);
is( $h->as_string( "<<\n" ), <<EOT);
A: foo<<
B: foo<<
 bar<<
C: foo<<
 bar<<
D: foo<<
\tbar<<
E: foo<<
  bar<<
F: foo<<
 bar<<
  baz<<
 baz<<
EOT

# Check with FALSE $HTML::Headers::TRANSLATE_UNDERSCORE
{
  local ( $HTTP::Headers::TRANSLATE_UNDERSCORE );
  $HTTP::Headers::TRANSLATE_UNDERSCORE = undef;    # avoid -w warning

  $h = mk;
  $h->header( abc_abc   => "foo" );
  $h->header( "abc-abc" => "bar" );

  is( $h->header( "ABC_ABC" ), "foo" );
  is( $h->header( "ABC-ABC" ), "bar" );
  ok( $h->remove_header( "Abc_Abc" ) );
  ok( !defined( $h->header( "abc_abc" ) ) );
  is( $h->header( "ABC-ABC" ), "bar" );
}

# Check if objects as header values works
require URI;
$h->header( URI => URI->new( "http://www.perl.org" ) );

is( $h->header( "URI" )->scheme, "http" );

$h->clear;
is( $h->as_string, "" );

$h->content_type( "text/plain" );
$h->header( content_md5   => "dummy" );
$h->header( "Content-Foo" => "foo" );
$h->header( Location      => "http:", xyzzy => "plugh!" );

is( $h->as_string, <<EOT);
Location: http:
Content-MD5: dummy
Content-Type: text/plain
Content-Foo: foo
Xyzzy: plugh!
EOT

my $c = $h->remove_content_headers;
is( $h->as_string, <<EOT);
Location: http:
Xyzzy: plugh!
EOT

is( $c->as_string, <<EOT);
Content-MD5: dummy
Content-Type: text/plain
Content-Foo: foo
EOT

$h = mk;
$h->content_type( "text/plain" );
$h->header( ":foo_bar", 1 );
$h->push_header( ":content_type", "text/html" );
is( j( $h->header_field_names ),
  "Content-Type|:content_type|:foo_bar" );
is( $h->header( 'Content-Type' ),  "text/plain" );
is( $h->header( ':Content_Type' ), undef );
is( $h->header( ':content_type' ), "text/html" );
is( $h->as_string,                 <<EOT);
Content-Type: text/plain
content_type: text/html
foo_bar: 1
EOT

# [RT#30579] IE6 appens "; length = NNNN" on If-Modified-Since (can we handle it)
$h = mk(
  if_modified_since => "Sat, 29 Oct 1994 19:43:31 GMT; length=34343" );
is( gmtime( $h->if_modified_since ), "Sat Oct 29 19:43:31 1994" );
