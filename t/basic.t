use OO::Actors;
use Test;

plan 3;

actor EventLog {
    has @!events;
    has $.limit;
    
    method log(Str $message) {
        push @!events, $message;
        shift @!events if @!events.elems > $!limit;
    }

    method latest-entries() {
        @!events.clone()
    }
}

my $el = EventLog.new(limit => 20);
ok $el ~~ Actor, 'Actor does Actor role';

await do for ^4 {
    start {
        $el.log('OMG') for ^100;
    }
}
pass 'Made many calls to Actor over many threads';

is (await $el.latest-entries()).elems, 20, 'Correct number of entries';
