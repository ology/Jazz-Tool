#!/usr/bin/env perl
use Mojolicious::Lite -signatures;

use Time::HiRes qw(time);

use lib 'lib';
use Jazztool ();

use constant TIME_LIMIT => 60 * 60 * 24 * 30; # 30 days

get '/' => sub ($c) {
  my $action = $c->param('action') || ''; # action to perform

  my $filename = 'public/' . time() . '.mid';

  my $jazz = Jazztool->new(
    filename => $filename,
    $c->param('tonic')    ? (tonic    => $c->param('tonic'))    : (),
    $c->param('octave')   ? (octave   => $c->param('octave'))   : (),
    $c->param('cpatch')   ? (cpatch   => $c->param('cpatch'))   : (),
    $c->param('bpatch')   ? (bpatch   => $c->param('bpatch'))   : (),
    $c->param('my_bpm')   ? (my_bpm   => $c->param('my_bpm'))   : (),
    $c->param('phrases')  ? (phrases  => $c->param('phrases'))  : (),
    $c->param('repeat')   ? (repeat   => $c->param('repeat'))   : (),
    $c->param('percent')  ? (percent  => $c->param('percent'))  : (),
    $c->param('hihat')    ? (hihat    => $c->param('hihat'))    : (),
    $c->param('do_drums') ? (do_drums => $c->param('do_drums')) : (),
    $c->param('do_bass')  ? (do_bass  => $c->param('do_bass'))  : (),
    $c->param('simple')   ? (simple   => $c->param('simple'))   : (),
    $c->param('reverb')   ? (reverb   => $c->param('reverb'))   : (),
  );
  my $msgs = $jazz->process;

  $filename =~ s/^public(.*)$/$1/;

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

<pre>
% for my $msg (@$msgs) {
  <%= $msg %>
% }
</pre>

@@ layouts/default.html.ep
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous">
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
