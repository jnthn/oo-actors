use OO::Actors;
use Test;

plan 3;

actor Cell {
    has $!state;

    method set($value) {
        $!state = $value;
    }

    method get ( ) {
        return $!state;
    }
}

my $cell = Cell.new;

isnt $cell, Nil, "Actor was properly created";

$cell.set("Hello, World!");
is (await $cell.get), "Hello, World!", "Retrieved correct value";

$cell.DESTROY;

throws-like { await $cell.get }, Actor::Killed, "Actor was properly destroyed";
