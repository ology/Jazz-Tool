#!/usr/bin/env perl
use Mojolicious::Lite -signatures;

use Time::HiRes qw(time);

use lib 'lib';
use Jazztool ();

use constant TIME_LIMIT => 60 * 60 * 24 * 30; # 30 days

get '/' => sub ($c) {
  my $action = $c->param('action') || ''; # action to perform

  my $filename = time() . '.mid';

  my $jazz = Jazztool->new(
    filename => $filename,
    tonic    => $c->param('tonic'),
    octave   => $c->param('octave'),
    cpatch   => $c->param('cpatch'),
    bpatch   => $c->param('bpatch'),
    bpm      => $c->param('bpm'),
    phrases  => $c->param('phrases'),
    repeat   => $c->param('repeat'),
    percent  => $c->param('percent'),
    hihat    => $c->param('hihat'),
    do_drums => $c->param('do_drums'),
    do_bass  => $c->param('do_bass'),
    simple   => $c->param('simple'),
    reverb   => $c->param('reverb'),
    verbose  => 1,
  );
  my $msgs = $jazz->process;

  $c->render(
    template => 'index',
    filename => $filename,
    msgs     => $msgs,
  );
} => 'index';

app->log->level('info');

app->start;

__DATA__

@@ index.html.ep
% layout 'default';
% title '12-Bar Improv Practice Tool';

@@ layouts/default.html.ep
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous">
    <script type='text/javascript' src='/midi.js'></script>
    <title><%= title %></title>
    <style>
      .padpage {
        padding-top: 10px;
      }
      .block {
        display: inline-block;
      }
      .small {
        font-size: small;
        color: darkgrey;
      }
    </style>
  </head>
  <body>
    <div class="container padpage">
      <h3><%= title %></h3>
      <%= content %>
      <p></p>
      <div id="footer" class="small">
        <hr>
        Built by <a href="http://gene.ology.net/">Gene</a>
        with <a href="https://www.perl.org/">Perl</a> and
        <a href="https://mojolicious.org/">Mojolicious</a>
      </div>
    </div>
  </body>
</html>
