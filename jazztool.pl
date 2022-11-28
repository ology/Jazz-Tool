#!/usr/bin/env perl
use Mojolicious::Lite -signatures;

use Time::HiRes qw(time);

use lib 'lib';
use Jazztool ();

use constant TIME_LIMIT => 60 * 60 * 24 * 30; # 30 days

get '/' => sub ($c) {
  my $submit   = $c->param('submit')   || 0;
  my $tonic    = $c->param('tonic')    || 'C';
  my $octave   = $c->param('octave')   || 4;
  my $cpatch   = $c->param('cpatch')   || 0;
  my $bpatch   = $c->param('bpatch')   // 35;
  my $my_bpm   = $c->param('my_bpm')   || 90;
  my $phrases  = $c->param('phrases')  || 12;
  my $repeat   = $c->param('repeat')   || 1;
  my $percent  = $c->param('percent')  || 25;
  my $hihat    = $c->param('hihat')    || 'closed';
  my $do_drums = $c->param('do_drums') || 0;
  my $do_bass  = $c->param('do_bass')  // 1;
  my $simple   = $c->param('simple')   || 0;
  my $reverb   = $c->param('reverb')   // 15;

  my $filename = '';
  my $msgs = [];

  if ($submit) {
    $filename = '/' . time() . '.mid';

    my $jazz = Jazztool->new(
      filename => 'public' . $filename,
      tonic    => $tonic,
      octave   => $octave,
      cpatch   => $cpatch,
      bpatch   => $bpatch,
      my_bpm   => $my_bpm,
      phrases  => $phrases,
      repeat   => $repeat,
      percent  => $percent,
      hihat    => $hihat,
      do_drums => $do_drums,
      do_bass  => $do_bass,
      simple   => $simple,
      reverb   => $reverb,
    );

    $msgs = $jazz->process;
  }

  $c->render(
    template => 'index',
    msgs     => $msgs,
    filename => $filename,
    tonic    => $tonic,
    octave   => $octave,
    cpatch   => $cpatch,
    bpatch   => $bpatch,
    my_bpm   => $my_bpm,
    phrases  => $phrases,
    repeat   => $repeat,
    percent  => $percent,
    hihat    => $hihat,
    do_drums => $do_drums ? 1 : 0,
    do_bass  => $do_bass ? 1 : 0,
    simple   => $simple ? 1 : 0,
    reverb   => $reverb,
  );
} => 'index';

app->log->level('info');

app->start;

__DATA__

@@ index.html.ep
% layout 'default';
% title '12-Bar Improv Practice Tool';

<form>
  <div class="form-group">
    <label for="tonic">Tonic:</label>
    <select class="form-control form-control-sm" id="tonic" name="tonic">
% for my $i (qw( C Db D Eb E F Gb G Ab A Bb B )) {
      <option value="<%= $i %>"><%= $i %></option>
% }
    </select>
  </div>
  <div class="form-group">
    <label for="octave">Octave:</label>
    <select class="form-control form-control-sm" id="octave" name="octave">
% for my $i (3, 4, 5, 6) {
      <option value="<%= $i %>"><%= $i %></option>
% }
    </select>
  </div>
  <div class="form-group">
    <label for="cpatch">Chord patch:</label>
    <input type="number" class="form-control form-control-sm" id="cpatch" name="cpatch" min="0" max="127" value="<%= $cpatch %>">
  </div>
  <div class="form-group">
    <label for="bpatch">Bass patch:</label>
    <input type="number" class="form-control form-control-sm" id="bpatch" name="bpatch" min="0" max="127" value="<%= $bpatch %>">
  </div>
  <div class="form-group">
    <label for="my_bpm">BPM:</label>
    <input type="number" class="form-control form-control-sm" id="my_bpm" name="my_bpm" min="1" max="200" value="<%= $my_bpm %>">
  </div>
  <div class="form-group">
    <label for="phrases">Phrases:</label>
    <input type="number" class="form-control form-control-sm" id="phrases" name="phrases" min="1" max="128" value="<%= $phrases %>">
  </div>
  <div class="form-group">
    <label for="repeat">Repeat:</label>
    <input type="number" class="form-control form-control-sm" id="repeat" name="repeat" min="1" max="64" value="<%= $repeat %>">
  </div>
  <div class="form-group">
    <label for="percent">Percent:</label>
    <input type="number" class="form-control form-control-sm" id="percent" name="percent" min="0" max="100" value="<%= $percent %>">
  </div>
  <div class="form-check form-check-inline">
    <input class="form-check-input" type="checkbox" id="do_bass" <%= $do_bass ? 'checked' : '' %>>
    <label class="form-check-label" for="do_bass">Bass</label>
  </div>
  <div class="form-check form-check-inline">
    <input class="form-check-input" type="checkbox" id="do_drums" <%= $do_drums ? 'checked' : '' %>>
    <label class="form-check-label" for="do_drums">Drums</label>
  </div>
  <div class="form-group">
    <label for="reverb">Drum reverb:</label>
    <input type="number" class="form-control form-control-sm" id="reverb" name="reverb" min="0" max="127" value="<%= $reverb %>">
  </div>
  <div class="form-group">
    <label for="hihat">Hihat:</label>
    <select class="form-control form-control-sm" id="hihat" name="hihat">
% for my $i (qw(pedal closed open)) {
      <option value="<%= $i %>"><%= $i %></option>
% }
    </select>
  </div>
  <input type="submit" class="btn btn-primary" name="submit" value="Submit">
</form>

% if ($filename) {
<p></p>
<a href="#" onClick="MIDIjs.play('<%= $filename %>');">Play MIDI</a>
|
<a href="<%= $filename %>">Download MIDI</a>
<p></p>
<pre>
%   for my $msg (@$msgs) {
  <%= $msg %>
%   }
</pre>
% }

@@ layouts/default.html.ep
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous">
    <script type='text/javascript' src='//www.midijs.net/lib/midi.js'></script>
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
