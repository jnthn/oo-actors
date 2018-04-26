use OO::Actors;
use Test;

plan 4;

actor Cell {
    has $!state;

    method set($value) {
        $!state = $value;
    }

    method get ( ) {
        return $!state;
    }
}

my $cell = Cell.new();

ok $cell.isa(Cell).result, "Actor was properly created";

$cell.set("Hello, World!").result;
is (await $cell.get), "Hello, World!", "Retrieved correct value";

$cell.DESTROY;

throws-like { await $cell.get }, Actor::Killed, "Actor was properly destroyed";

subtest {
    plan 1;

    my $cell = Cell.new;

    $cell.DESTROY;

    throws-like { await $cell.get }, Actor::Killed, "Actor was destroyed";
}, "Destructor don't assume any prior hidden setup on actor";
