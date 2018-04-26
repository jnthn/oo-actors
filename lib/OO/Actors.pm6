sub task($vow, $receiver, $method, $capture) {
    sub {
        $vow.keep($method($receiver, |$capture));
        CATCH { $vow.break($_) }
    }
}

sub spawn($channel) {
    Thread.start({
        loop {
            my $task = $channel.receive;
            $task();
            Thread.yield;
        }
        CATCH {
            default { True }
        }
    }, :app_lifetime)
}

role Actor {
    has $!process;
    has $!mailbox = Channel.new;
    has $!lock    = Lock.new;

    method !post($method, $capture) {
        # avoids promises on self-sends
        if ($!process && $*THREAD.id == $!process.id) {
            return $method(self, |$capture);
        }
        else {
            try {
                my $promise = Promise.new;
                my $vow     = $promise.vow;

                $!mailbox.send(task($vow, self, $method, $capture));

                $!lock.protect({
                    $!process = spawn($!mailbox) unless $!process;
                });

                return $promise;

                CATCH {
                    $vow.break($_);
                    return $promise;
                }
            }
        }
    }

    submethod DESTROY {
        $!lock.protect({
            $!mailbox.close;

            # couldn't join on self-send
            $!process.finish unless $*THREAD.id == $!process.id;
        })
    }
}

class MetamodelX::ActorHOW is Metamodel::ClassHOW {
    my %bypass = :new, :bless, :BUILDALL, :BUILD, :DESTROY, 'dispatch:<!>' => True;

    method find_method(Mu \obj, $name, |) {
        my $method = callsame;
        my $post = self.find_private_method(obj, 'post');
        %bypass{$name} || !$method
            ?? $method
            !!  -> \obj, |capture { $post(obj, $method, capture); }
    }

    method compose(Mu \type) {
        self.add_role(type, Actor);
        self.Metamodel::ClassHOW::compose(type);
    }

    method publish_method_cache(|) { }
}

my package EXPORTHOW {
    package DECLARE {
        constant actor = MetamodelX::ActorHOW;
    }
}
