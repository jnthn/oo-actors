use OO::Actors;
use Test;

plan 1;

actor Bomb {
    has $.level = 0;

    method fork {
        if $.level > 1 {
            my $first  = self.new(level => $.level - 1).fork();
            my $second = self.new(level => $.level - 2).fork();

            return $first.result() + $second.result();
        }
        else {
            return $.level;
        }
    }
}

my $initial-bomb = Bomb.new(level => 9);

my $promise = $initial-bomb.fork;

is (await $promise), 34, "Nested chain of actors spawned successfully"
