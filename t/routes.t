use Mojo::Base -strict;

use Mojo::File qw(curfile);
use Test::Mojo::Session;
use Test::More;

my $t = Test::Mojo::Session->new(curfile->dirname->sibling('jazztool.pl'));

subtest page_load => sub {
  $t->get_ok('/')
    ->status_is(200)
#    ->session_has('/session')
  ;
};

done_testing();
