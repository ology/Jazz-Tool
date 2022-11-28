package Jazztool;

use lib map { "$ENV{HOME}/sandbox/$_/lib" } qw(MIDI-Drummer-Tiny MIDI-Util Music-Cadence Music-MelodicDevice-Transposition); # local author libs

use Moo;

use Data::Dumper::Compact qw(ddc);
use MIDI::Drummer::Tiny ();
use MIDI::Util qw(set_chan_patch midi_format);
use Music::Cadence ();
use Music::Chord::Note ();
use Music::MelodicDevice::Transposition ();
use Music::Note ();

has filename => (is => 'ro', required => 1);               # MIDI file name
has msgs     => (is => 'rw', default => sub { [] });       # bucket for output messages
has tonic    => (is => 'ro', default => sub { 'C' });      # note to transpose things to
has octave   => (is => 'ro', default => sub { 4 });        # octave of chord notes
has cpatch   => (is => 'ro', default => sub { 0 });        # 0=piano, etc general midi
has bpatch   => (is => 'ro', default => sub { 35 });       # 35=fretless bass, etc
has my_bpm   => (is => 'ro', default => sub { 90 });       # beats per minute
has phrases  => (is => 'ro', default => sub { 12 });       # number of 4/4 bars
has repeat   => (is => 'ro', default => sub { 1 });        # number of times to repeat
has percent  => (is => 'ro', default => sub { 25 });       # maximum half-note percentage
has hihat    => (is => 'ro', default => sub { 'closed' }); # pedal, closed, open
has do_drums => (is => 'ro', default => sub { 0 });        # to drum, or not to drum?
has do_bass  => (is => 'ro', default => sub { 1 });        # to have a parallel bass or not
has bassline => (is => 'rw', default => sub { [] });       # the notes of the bass-line
has simple   => (is => 'ro', default => sub { 0 });        # don't randomly choose a transition
has reverb   => (is => 'ro', default => sub { 15 });       # more dry than wet by default
has drummer  => (is => 'lazy');

sub _build_drummer {
    my ($self) = @_;
    my $d = MIDI::Drummer::Tiny->new(
        file   => $self->filename,
        bars   => $self->phrases,
        bpm    => $self->my_bpm,
        reverb => $self->reverb,
    );
    return $d;
}

sub process {
    my ($self) = @_;

    $self->drummer->sync(
        sub { drums($self) },
        sub { chords($self) },
        sub { bass($self) },
    );

    $self->drummer->write;

    return $self->msgs;
}

sub drums {
    my ($self) = @_;
    if ($self->do_drums) {
        $self->drummer->metronome44swing($self->drummer->bars * $self->repeat);
        $self->drummer->note($self->drummer->whole, $self->drummer->kick, $self->drummer->ride1);
    }
    else {
        my $patch = $self->hihat . '_hh';
        $self->drummer->count_in({
            bars  => $self->drummer->bars * $self->repeat,
            patch => $self->drummer->$patch(),
        });
    }
}

sub bass {
    my ($self) = @_;
    if ($self->do_bass) {
        set_chan_patch($self->drummer->score, 1, $self->bpatch);

        for (1 .. $self->repeat) {
            for my $n ($self->bassline->@*) {
                $n =~ s/^([A-G][#b]?)\d$/$1 . 3/e; # change to octave 3
                $self->drummer->note($self->drummer->whole, midi_format($n));
            }
        }
    }
}

sub chords {
    my ($self) = @_;
    set_chan_patch($self->drummer->score, 0, $self->cpatch);

    my $md = Music::MelodicDevice::Transposition->new;
    my $cn = Music::Chord::Note->new;
    my $mc = Music::Cadence->new(
        key    => $self->tonic,
        octave => $self->octave,
        format => 'midi',
    );

    # all chords in C initially
    my $transpose = $cn->scale($self->tonic);

    # get the chords - bars and network
    my @bars = bars();
    my %net  = net();

    my @specs; # bucket for the actual MIDI notes to play
    my @bass_notes; # bucket for the notes of the bass-line
    my @msgs; # bucket for process progress

    for my $n (0 .. $self->drummer->bars - 1) {
        my @pool = $bars[ $n % @bars ]->@*;
        my $chord = $self->simple ? $pool[0] : $pool[ int rand @pool ];
        my $new_chord = transposition($transpose, $chord, $md);
        my @notes = $cn->chord_with_octave($new_chord, $self->octave);

        $_ = accidental($_) for @notes; # convert to flat

        push @bass_notes, $notes[0]; # accumulate the bass notes to play

        my $names = $new_chord; # chord name

        my @spec; # for accumulating within the loop

        if (!$self->simple && $self->percent >= int(rand 100) + 1) {
            push @spec, [ $self->drummer->half, @notes ];

            @pool = $net{$chord}->@*;
            $chord = $pool[ int rand @pool ];
            my $new_chord = transposition($transpose, $chord, $md);
            @notes = $cn->chord_with_octave($new_chord, $self->octave);

            $_ = accidental($_) for @notes; # convert to flat

            $names .= "-$new_chord"; # chord name

            push @spec, [ $self->drummer->half, @notes ];
        }
        else {
            push @spec, [ $self->drummer->whole, @notes ];
        }

        push @msgs, sprintf '%*d. %13s: %s',
            length($self->phrases), $n + 1, $names, ddc(\@spec);

        push @specs, @spec; # accumulate the note specifications
    }

    $self->bassline(\@bass_notes);
    $self->msgs(\@msgs);

    # actually add the MIDI notes to the score
    for (1 .. $self->repeat) {
        $self->drummer->note(midi_format(@$_)) for @specs;
    }

    # finally end with a cadence chord
    my $cadence = $mc->cadence(type => 'imperfect');
    $self->drummer->note($self->drummer->whole, $cadence->[0]->@*);
}

sub transposition {
    my ($transpose, $chord, $md) = @_;
    if ($transpose && $chord =~ /^([A-G][#b]?)(.*)$/) {
        my $note = $1;
        my $flav = $2;
        my $transposed = $md->transpose($transpose, [$note]);
        (my $new_note = $transposed->[0]) =~ s/^([A-G][#b]?).*$/$1/;
        $new_note = accidental($new_note); # convert to flat
        $chord = $new_note;
        $chord .= $flav if $flav;
    }
    return $chord;
}

sub accidental {
    my ($string) = @_; # note or chord name
    if ($string =~ /^([A-G]#)(.*)?$/) { # is the note sharp?
        my $note = $1;
        my $flav = $2;
        my $mn = Music::Note->new($note, 'isobase');
        $mn->en_eq('b'); # convert to flat
        $string = $mn->format('isobase');
        $string .= $flav if $flav;
    }
    return $string;
}

sub bars {
    no warnings qw(qw);
    return (                                  # bar
        [qw( C7 CM7 C#m7                  )], #  1
        [qw( C7 F7  Bm7  FM7    C#m7      )], #  2
        [qw( C7 Am7 Em7  BM7              )], #  3
        [qw( C7 Gm7 Dbm7 AbM7             )], #  4
        [qw( F7 FM7                       )], #  5
        [qw( F7 Bb7 Gbm7 Gbdim7 Fm7       )], #  6
        [qw( C7 Em7 EbM7 EM7              )], #  7
        [qw( C7 A7  Bb7  Ebm7   Em7       )], #  8
        [qw( G7 D7  Dm7  Ab7    DbM7 DM7  )], #  9
        [qw( G7 F7  Abm7 Db7    Dm7  DbM7 )], # 10
        [qw( C7 Em7 FM7                   )], # 11
        [qw( C7 G7  Dm7  Ab7    Abm7 DM7  )], # 12
    );
}

sub net {
    no warnings qw(qw);
    return (
        'A7'     => [qw( Ebm7 D7 Dm7 Ab7 DM7 Abm7 )],
        'Ab7'    => [qw( DbM7 Dm7 G7 )],
        'AbM7'   => [qw( GbM7 )],
        'Abm7'   => [qw( Db Gm7 Db7 )],
        'Am7'    => [qw( D7 Abm7 )],
        'B7'     => [qw( C7 Em7 EM7 Bb7 )],
        'BM7'    => [qw( BbM7 )],
        'Bb7'    => [qw( C7 Ebm7 Em7 EbM7 A7 )],
        'Bbm7'   => [qw( Am7 )],
        'Bm7'    => [qw( E7 Bbm7 )],
        'C#m7'   => [qw( Gb7 )],
        'C7'     => [qw( C7 F7 Gm7 FM7 A7 Em7 B7 G7 Dm7 Ab7 )],
        'CM7'    => [qw( Bm7 FM7 C#m7 Ebm7 AbM7 )],
        'D7'     => [qw( Gm7 Dbm7 )],
        'DM7'    => [qw( DbM7 Db )],
        'Db7'    => [qw( C7 CM7 )],
        'DbM7'   => [qw( Dm7 CM7 )],
        'Dbm7'   => [qw( Gb7 )],
        'Dm7'    => [qw( Dbm7 G7 Db7 Db )],
        'E7'     => [qw( Am7 )],
        'EM7'    => [qw( Em7 )],
        'EbM7'   => [qw( Ebm7 DM7 )],
        'Ebm7'   => [qw( Ab7 Dm7 Ebm7 )],
        'Em7'    => [qw( Dm7 A7 Ebm7 Edim7 )],
        'Edim7'  => [qw( Dm7 )],
        'F7'     => [qw( C7 Bb7 Eb7 Gbm7 Gbdim7 Em7 )],
        'FM7'    => [qw( Em7 Fm7 Gbm7 )],
        'Fm7'    => [qw( Em7 Bb7 )],
        'G7'     => [qw( G7 F7 Abm7 C7 Em7 )],
        'Gb7'    => [qw( Bm7 BM7 FM7 )],
        'GbM7'   => [qw( FM7 )],
        'Gbm7'   => [qw( B7 )],
        'Gbdim7' => [qw( Em7 )],
        'Gm7'    => [qw( C7 Gb7 )],
    );
}

1;
