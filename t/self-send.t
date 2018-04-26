use OO::Actors;
use Test;

plan 2;

actor Example {
    method greet($name) { "Hello, $name!" }

    method test-with($name) {
        subtest {
            plan 1;

            my $result = self.greet($name);

            isa-ok $result, Str, "Self-sends are strict/normal method calls";
        }, "Internal send";
    }
}

my $example = Example.new;

isa-ok $example.greet("World"), Promise, "External sends are asynchronous calls";

$example.test-with("Absurd World").result;
