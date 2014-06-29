package Mojolicious::Plugin::LessRenderer;
use Mojo::Base 'Mojolicious::Plugin';

use CSS::LESSp;
use CSS::Compressor qw( css_compress );

use Mojo::ByteStream 'b';
use Mojo::Collection 'c';


our $VERSION = '0.01';


# Register Plugin
sub register {
  my ($plugin, $mojo) = @_;

  # Add 'less' handler
  $mojo->renderer->add_handler(
    less => sub {
      my ($r, $c, $output, $options) = @_;

      # Get styles from cache
      my ($cache_result, $path) = _get_from_cache($r, $options);

      # Set cache as output
      if ($cache_result) {
	$$output = $cache_result;
	return 1;
      };

      # Get data
      my $less = $options->{inline} ? $path : _get_data($r, $c, $path, $options);

      return unless $less;

      # Convert less to css
      $$output = c(CSS::LESSp->parse($less))->join('');

      # Set styles to cache
      $r->cache->set($options->{cache} => $$output);

      return 1;
    }
  );

  # Add 'lessc' handler
  $mojo->renderer->add_handler(
    lessc => sub {
      my ($r, $c, $output, $options) = @_;

      # Get styles from cache
      my ($cache_result, $path) = _get_from_cache($r, $options);

      # Set cache as output
      if ($cache_result) {
	$$output = $cache_result;
	return 1;
      };

      # Get data
      my $less = _get_data($r, $c, $path, $options);
      return unless $less;

      # Convert less to compressed css
      $$output = css_compress(c(CSS::LESSp->parse($less))->join(''));

      # Set styles to cache
      $r->cache->set($options->{cache} => $$output);

      return 1;
    }
  );

  $mojo->helper(
    less_stylesheet => sub { _stylesheet(shift, 0, @_) }
  );

  $mojo->helper(
    lessc_stylesheet => sub { _stylesheet(shift, 1, @_) }
  );

};


# Stylesheet
sub _stylesheet {
  my $c = shift;
  my $compress = shift(@_) ? 1 : 0;
  my $style = pop;

  # No content
  return unless ref $style eq 'CODE';

  # Convert LESS to CSS
  my $css = c(CSS::LESSp->parse($style->()))->join('');

  # Compress CSS
  $css = css_compress($css) if $compress;

  # Surround content with CDATA
  my $cb = sub { "/*<![CDATA[*/\n" . $css . "\n/*]]>*/" };

  # "link" or "style" tag
  return $c->tag(style => @_, $cb);
};


# Get data from cache
sub _get_from_cache {
  my ($r, $options) = @_;

  $options ||= {};

  # Todo: First render using ep!

  # Get path
  my $path = $options->{inline} || $r->template_path($options);

  # No path defined
  return unless defined $path;

  # Generate caching key from path
  my $key = $options->{cache} = b($path)->encode('UTF-8')->md5_sum;

  # Compile helpers and stash values
  return (($r->cache->get($key) || undef), $path);
};


# Get data from file or data section
sub _get_data {
  my ($r, $c, $path, $options) = @_;

  # Not found
  return unless my $t = $r->template_name($options);

  # Try template
  if (-r $path) {
    $c->app->log->debug(qq{Rendering less template "$t".});
    return b($path)->slurp;
  }

  # Try DATA section
  elsif (my $less = $r->get_data_template($options)) {
    $c->app->log->debug(qq{Rendering less template "$t" from DATA section.});
    return $less;
  };

  return;
};


1;


__END__

=pod

=head1 NAME

Mojolicious::Plugin::LessRenderer - Use LESS in your Mojolicious templates

B<Due to many bugs in L<CSS::LESSp> I cannot recommend using this plugin!!!>
B<Please consider using L<Mojolicious::Plugin::AssetPack> instead!>

=head1 SYNOPSIS

  $app->plugin('LessRenderer');


=head1 DESCRIPTION

L<Mojolicious::Plugin::Piwik> is a simple plugin for embedding
Piwik Analysis to your Mojolicious app.


=head1 METHODS

=head2 C<register>

  # Mojolicious
  $app->plugin('LessRenderer');

  # Mojolicious::Lite
  plugin 'LessRenderer';

Called when registering the plugin.


=head1 HANDLER

=head2 C<less>

Converts a LESS stylesheet to CSS on the fly.
Supports template caching.


=head2 C<lessc>

Converts a LESS stylesheet to a compressed CSS on the fly.
Supports template caching.

B<This handler is EXPERIMENTAL and may change without warnings.>


=head1 HELPERS

=head2 C<less_stylesheet>

  # In a template
  %= less_stylesheet begin
    p {
      color: #000;
      a {
        color: red;
      }
    }
    p {
      font-size: 12pt;
    }
  % end

Renders LESS stylesheet code inline.


=head2 C<lessc_stylesheet>

  # In a template
  %= lessc_stylesheet begin
    p {
      color: #000;
      a {
        color: red;
      }
    }
    p {
      font-size: 12pt;
    }
  % end

Renders LESS stylesheet code inline and
compresses it on the fly.

B<This helper is EXPERIMENTAL and may change without warnings.>


=head1 DEPENDENCIES

L<Mojolicious>,
L<CSS::LESSp>,
L<CSS::Compressor>.


=head1 BUGS

As this plugin uses L<CSS::LESSp> and L<CSS::Compressor>,
it has their limitations.


=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-LessRenderer


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Nils Diewald.

This program is free software, you can redistribute it
and/or modify it under the same terms as Perl.

=cut
