# OO::Actors

A partial Actors implementation, which will hopefully grow up into a fairly
rich one. For now, it may be enough to be useful for what you need.

## Writing an actor

The `OO::Actors` module provides an `actor` declarator. Beyond that, it's very
much like writing a normal class.

    use Actors;

    enum Severity <Fatal Error Warning Notice>;

    actor EventLog {
        has %!events-by-level{Severity};
        
        method log(Severity $level, Str $message) {
            push %!events-by-level{$level}, $message;
        }

        method latest-entries(Severity $level-limit) {
            my @found;
            for %!events-by-level.kv -> $level, @messages {
                next if $level > $level-limit;
                push @found, @messages;
            }
            return @found;
        }
    }

Method calls to an actor are asynchronous. That is, making a method call puts
the method name and arguments into a queue. Note that this means you'd better
not pass things and then mutate them! Methods are run in the thread pool, one
call at a time.

## Getting results

Since method calls on an actor are asynchronous, how do you cope with query
methods? Each method call on an actor returns a Promise. This can be used to
get the result;

    say await $log.latest-entries(Error);
