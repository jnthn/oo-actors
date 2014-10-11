role Actor {
    has @!inbox;
    has $!working = False;
    has $!inbox-lock = Lock.new;

    method !post($method, $capture) {
        my $p = Promise.new;
        my $v = $p.vow;
        $!inbox-lock.protect({
            @!inbox.push({
                $v.keep($method(self, |$capture));
                CATCH { $v.break($_); #`( And let it escape to supervisor `) }
            });
            unless $!working {
                $*SCHEDULER.cue({ self!process-inbox() });
            }
        });
        $p
    }
    
    method !process-inbox() {
        loop {
            my $task;
            $!inbox-lock.protect({
                unless $!working || @!inbox.elems == 0 {
                    $!working = True;
                    $task = @!inbox.shift;
                }
            });
            if $task {
                my $failure;
                try $task();
                if $! {
                    say "Supervision NYI; $!";
                    exit(1);
                }
                else {
                    $!inbox-lock.protect({
                        $!working = False;
                    });
                }
            }
        }
    }
}

class MetamodelX::ActorHOW is Metamodel::ClassHOW {
    my %bypass = :new, :bless, :BUILDALL, :BUILD, 'dispatch:<!>' => True;
    
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
