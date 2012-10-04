#!/usr/bin/env perl
use Test::Mojo;
use Test::More tests => 4;
use Mojolicious::Lite;
$|++;
use lib ('../lib', '../../lib');

my $t = Test::Mojo->new;

my $app = $t->app;

$app->plugin('LessRenderer');

my $c = Mojolicious::Controller->new;
$c->app($app);

my $css = << 'CSS';
p {
  color: black;
  a {
    color: red;
  }
}
p {
  font-size: 12pt;
}
CSS

like($c->less_stylesheet(sub { $css }), qr/p a /, 'less_stylesheet' );
unlike($c->lessc_stylesheet(sub { $css }), qr/\s\s/, 'lessc_stylesheet' );

like($c->render_partial(
  inline => $css,
  format => 'css',
  handler => 'less'
), qr/p a /, 'less_handler');

unlike($c->render_partial(
  inline => $css,
  format => 'css',
  handler => 'lessc'
), qr/\s\s/, 'lessc_handler');

